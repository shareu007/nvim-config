# Portable Neovim C/C++ Setup

A reproducible, user-level Neovim configuration for C and C++ development. It installs without replacing a system-provided Vim or Neovim.

## Features

- Latest stable Neovim installed under `~/.local/opt/nvim`
- Plugin management with `lazy.nvim`
- File explorer with `neo-tree.nvim`
- C/C++ syntax highlighting with Treesitter
- Code navigation, diagnostics, and refactoring with clangd
- Completion with nvim-cmp
- Format-on-save with clang-format
- Debugging with nvim-dap, nvim-dap-ui, and codelldb
- Nerd Symbols font fallback for terminal icons

## Supported systems

The installer supports Linux on x86_64 and ARM64. If required dependencies are missing, it can install them with `apt`, `dnf`, or `pacman`; in that case, you may be prompted for your sudo password.

Required tools:

```text
curl git tar unzip cc python3 python3-pip fontconfig
```

## Installation

Clone the repository to any directory and run the installer:

```bash
git clone https://github.com/shareu007/nvim-config.git
cd nvim-config
./install.sh
```

The script installs Neovim, fonts, plugins, clangd, clang-format, and codelldb. Existing Neovim installations and configuration directories are moved to timestamped backups before replacement.

After installation, open a new terminal and run:

```bash
nvim
```

Re-run `./install.sh` at any time to update or repair the installation.

## Key mappings

| Key | Action |
|---|---|
| `Space e` | Toggle the file explorer |
| `Ctrl-h/j/k/l` | Move between the file explorer and editor splits |
| `Enter` | Open the selected file in Neo-tree |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Show hover documentation |
| `Space rn` | Rename a symbol |
| `Space ca` | Show code actions |
| `Space f` | Format the current file |
| `Space db` | Toggle a breakpoint |
| `F5` | Start or continue debugging |
| `F10/F11/F12` | Step over, step into, or step out |

## Repository layout

- `nvim/init.lua` — Neovim and plugin configuration
- `nvim/lazy-lock.json` — pinned plugin revisions
- `install.sh` — idempotent installation and update script

Neovim, fonts, plugins, and development tools are installed in the current user's home directory. The installer only invokes sudo when system-level prerequisites are missing.

## Updating this configuration

Edit the files under `nvim/`, commit your changes, and run:

```bash
./install.sh
```

This deploys the repository configuration to `~/.config/nvim`.
