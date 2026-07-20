#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly USER_HOME="${HOME:?HOME is not set}"
readonly CONFIG_ROOT="${XDG_CONFIG_HOME:-${USER_HOME}/.config}"
readonly DATA_ROOT="${XDG_DATA_HOME:-${USER_HOME}/.local/share}"
readonly BIN_DIR="${USER_HOME}/.local/bin"
readonly NVIM_DIR="${USER_HOME}/.local/opt/nvim"
readonly NVIM_CONFIG_DIR="${CONFIG_ROOT}/nvim"
readonly NVIM_DATA_DIR="${DATA_ROOT}/nvim"
readonly FONT_DIR="${DATA_ROOT}/fonts"
readonly FONTCONFIG_DIR="${CONFIG_ROOT}/fontconfig/conf.d"
readonly PROFILE_FILE="${USER_HOME}/.profile"

log() { printf '\n==> %s\n' "$*"; }
die() { printf '错误: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "缺少命令：$1"; }

install_dependencies() {
  local missing=()
  local command_name
  for command_name in curl git tar unzip cc python3; do
    command -v "${command_name}" >/dev/null 2>&1 || missing+=("${command_name}")
  done
  python3 -m pip --version >/dev/null 2>&1 || missing+=("python3-pip")
  ((${#missing[@]} == 0)) && return

  log "缺少基础依赖：${missing[*]}"
  command -v sudo >/dev/null 2>&1 || die "请先安装缺少的基础依赖"

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y curl git tar unzip build-essential python3 python3-pip fontconfig ca-certificates
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y curl git tar unzip gcc gcc-c++ python3 python3-pip fontconfig ca-certificates
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --needed curl git tar unzip base-devel python python-pip fontconfig ca-certificates
  else
    die "不支持自动安装当前系统的依赖，请手动安装：${missing[*]}"
  fi
}

install_dependencies
for command_name in curl git tar unzip cc python3; do need "${command_name}"; done

case "$(uname -m)" in
  x86_64|amd64) nvim_arch="x86_64" ;;
  aarch64|arm64) nvim_arch="arm64" ;;
  *) die "暂不支持的 CPU 架构：$(uname -m)" ;;
esac

readonly NVIM_ASSET="nvim-linux-${nvim_arch}.tar.gz"
readonly NVIM_URL="https://github.com/neovim/neovim-releases/releases/latest/download/${NVIM_ASSET}"
readonly FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip"
readonly TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT

log "下载并安装最新版 Neovim (${nvim_arch})"
curl -fL --retry 3 --connect-timeout 20 "${NVIM_URL}" -o "${TEMP_DIR}/${NVIM_ASSET}"
mkdir -p "${TEMP_DIR}/nvim"
tar -xzf "${TEMP_DIR}/${NVIM_ASSET}" --strip-components=1 -C "${TEMP_DIR}/nvim"

mkdir -p "$(dirname -- "${NVIM_DIR}")" "${BIN_DIR}"
if [[ -e "${NVIM_DIR}" || -L "${NVIM_DIR}" ]]; then
  backup_path="${NVIM_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
  log "备份旧 Neovim 到 ${backup_path}"
  mv -- "${NVIM_DIR}" "${backup_path}"
fi
mv -- "${TEMP_DIR}/nvim" "${NVIM_DIR}"
if [[ -e "${BIN_DIR}/nvim" && ! -L "${BIN_DIR}/nvim" ]]; then
  mv -- "${BIN_DIR}/nvim" "${BIN_DIR}/nvim.backup.$(date +%Y%m%d-%H%M%S)"
fi
ln -sfn -- "${NVIM_DIR}/bin/nvim" "${BIN_DIR}/nvim"

log "安装 Nerd Symbols 字体"
curl -fL --retry 3 --connect-timeout 20 "${FONT_URL}" -o "${TEMP_DIR}/NerdFontsSymbolsOnly.zip"
mkdir -p "${FONT_DIR}" "${FONTCONFIG_DIR}" "${TEMP_DIR}/font"
unzip -q -j "${TEMP_DIR}/NerdFontsSymbolsOnly.zip" \
  'SymbolsNerdFont-Regular.ttf' \
  'SymbolsNerdFontMono-Regular.ttf' \
  '10-nerd-font-symbols.conf' \
  -d "${TEMP_DIR}/font"
install -m 644 "${TEMP_DIR}/font/SymbolsNerdFont-Regular.ttf" "${FONT_DIR}/"
install -m 644 "${TEMP_DIR}/font/SymbolsNerdFontMono-Regular.ttf" "${FONT_DIR}/"
install -m 644 "${TEMP_DIR}/font/10-nerd-font-symbols.conf" "${FONTCONFIG_DIR}/"
command -v fc-cache >/dev/null 2>&1 && fc-cache -f "${FONT_DIR}" >/dev/null

log "安装 Neovim 配置"
if [[ -e "${NVIM_CONFIG_DIR}" || -L "${NVIM_CONFIG_DIR}" ]] \
  && { [[ ! -f "${NVIM_CONFIG_DIR}/init.lua" ]] \
    || ! cmp -s "${SCRIPT_DIR}/nvim/init.lua" "${NVIM_CONFIG_DIR}/init.lua"; }; then
  config_backup="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
  log "备份旧配置到 ${config_backup}"
  mv -- "${NVIM_CONFIG_DIR}" "${config_backup}"
fi
mkdir -p "${NVIM_CONFIG_DIR}"
install -m 644 "${SCRIPT_DIR}/nvim/init.lua" "${NVIM_CONFIG_DIR}/init.lua"
install -m 644 "${SCRIPT_DIR}/nvim/lazy-lock.json" "${NVIM_CONFIG_DIR}/lazy-lock.json"

if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
  touch "${PROFILE_FILE}"
  if ! grep -Fq '# nvim-config: local bin' "${PROFILE_FILE}"; then
    {
      printf '\n# nvim-config: local bin\n'
      printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    } >> "${PROFILE_FILE}"
  fi
fi

log "同步插件和 C/C++ 开发工具"
"${BIN_DIR}/nvim" --headless "+Lazy! sync" +qa
"${BIN_DIR}/nvim" --headless "+MasonToolsInstallSync" +qa

if ! command -v clang-format >/dev/null 2>&1 && [[ ! -x "${NVIM_DATA_DIR}/mason/bin/clang-format" ]]; then
  if python3 -m pip --version >/dev/null 2>&1; then
    format_dir="${NVIM_DATA_DIR}/mason/packages/clang-format-pip"
    python3 -m pip install --upgrade --target "${format_dir}" clang-format
    mkdir -p "${NVIM_DATA_DIR}/mason/bin"
    ln -sfn -- "../packages/clang-format-pip/clang_format/data/bin/clang-format" \
      "${NVIM_DATA_DIR}/mason/bin/clang-format"
  else
    die "无法安装 clang-format：请先安装 python3-pip 后重新运行此脚本"
  fi
fi

log "验证安装"
"${BIN_DIR}/nvim" --headless \
  '+lua assert(vim.fn.exists(":Neotree") == 2, "Neo-tree 未加载")' \
  '+lua assert(vim.fn.executable("clangd") == 1, "clangd 不可用")' \
  '+lua assert(vim.fn.executable("clang-format") == 1, "clang-format 不可用")' \
  '+lua print("Neovim 配置验证通过")' +qa

printf '\n安装完成：%s\n' "$("${BIN_DIR}/nvim" --version | head -n 1)"
printf '请重新打开终端，然后运行：nvim\n'
