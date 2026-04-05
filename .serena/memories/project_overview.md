# .dotfiles Project Overview

## Purpose
macOS dotfiles and system configuration automation. Automates development environment setup including shell (ZSH/Oh-My-Zsh/Powerlevel10k), editors (Vim, Neovim/LazyVim), Git workflows, and Homebrew package management.

## Structure
- `install.sh` - Main entry point (full system setup)
- `install_packages.sh` - Profile-based package installer (reads packages.json)
- `install-node.sh` - Legacy node-based installer (runs index.js)
- `packages.json` - Package profiles (common/private/business)
- `homedir/` - Dotfiles symlinked to ~ via GNU stow
- `lib_sh/` - Shell helper libraries (echos.sh, requirers.sh, asdf_setup.sh)
- `nvim/` - Neovim/LazyVim configuration
- `configs/` - App configurations
- `scripts/` - Utility shell scripts

## Tech Stack
- Bash shell scripts
- Node.js (legacy installer via index.js)
- Homebrew for package management
- GNU Stow for symlink management
- Lua for Neovim config

## Key Commands
- `./install.sh` - Full system setup
- `./install_packages.sh <profile>` - Install packages by profile
- `brew bundle` - Install Homebrew packages from Brewfile
- `shellcheck <script.sh>` - Lint shell scripts
- `stylua nvim/` - Format Lua files

## No test suite. npm test is not implemented.
