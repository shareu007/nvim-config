# Neovim C/C++ 开发配置

一套可重复部署的 Neovim 配置，采用用户级安装，不需要覆盖系统自带的 Vim/Neovim。

## 包含内容

- 最新稳定版 Neovim，安装到 `~/.local/opt/nvim`
- `lazy.nvim` 插件管理
- `neo-tree.nvim` 文件树
- Treesitter C/C++ 语法高亮
- clangd 代码导航、诊断和重构
- nvim-cmp 自动补全
- clang-format 保存时格式化
- nvim-dap、nvim-dap-ui 和 codelldb 调试
- Nerd Symbols 字体回退，修复终端图标

## 一键安装

支持 Linux x86_64 和 ARM64。脚本会在缺少基础依赖时尝试通过 `apt`、`dnf` 或 `pacman` 安装；这时系统可能要求输入 sudo 密码。

```text
curl git tar unzip cc python3 python3-pip fontconfig
```

克隆仓库后运行：

```bash
git clone https://github.com/你的用户名/nvim-config.git ~/lsy/nvim-config
cd ~/lsy/nvim-config
./install.sh
```

脚本会下载 Neovim、字体、插件和 C/C++ 工具。已有 Neovim 或配置会先备份为带时间戳的目录。重复运行脚本可以更新或修复安装。

安装结束后重新打开终端，再运行：

```bash
nvim
```

## 常用快捷键

| 快捷键 | 功能 |
|---|---|
| `Space e` | 显示/隐藏文件树 |
| `Ctrl-h/j/k/l` | 在文件树和各分屏间移动 |
| `Enter` | 在文件树中打开文件 |
| `gd` | 跳转到定义 |
| `gr` | 查找引用 |
| `K` | 查看悬浮文档 |
| `Space rn` | 重命名符号 |
| `Space ca` | 代码操作 |
| `Space f` | 格式化当前文件 |
| `Space db` | 切换断点 |
| `F5` | 启动或继续调试 |
| `F10/F11/F12` | 越过/进入/跳出 |

## 配置文件

- `nvim/init.lua`：Neovim 和插件配置
- `nvim/lazy-lock.json`：插件版本锁文件
- `install.sh`：一键安装和更新脚本

修改配置后，可以重新执行 `./install.sh` 部署到当前用户目录。

Neovim、字体、插件和开发工具均安装在当前用户目录中；只有缺少上述系统基础依赖时才会调用 sudo。

## 上传到 GitHub

在 GitHub 新建一个空仓库，然后执行：

```bash
cd ~/lsy/nvim-config
git add .
git commit -m "Add portable Neovim C development setup"
git remote add origin https://github.com/你的用户名/nvim-config.git
git push -u origin main
```

