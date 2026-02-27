# macOS Dotfiles

Automated macOS development environment setup using **Tuckr** (dotfile manager) and **GNU Make** (orchestration).

## What's included

- **Shell**: ZSH + Oh-My-Zsh + Powerlevel10k
- **Editor**: Vim (Vundle plugins) + Neovim (LazyVim)
- **Git**: Aliases, hooks, templates, conventional commits
- **Tools**: asdf, tmux, screen, Node.js, Ruby
- **macOS defaults**: ~100 system preferences across security, Finder, Dock, Safari, and more
- **Packages**: Profile-based Homebrew installation (common, private, work, entertainment)

## Quick Start

### Fresh machine

```bash
git clone --recurse-submodules https://github.com/marcboeker/dotfiles ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs Xcode Command Line Tools, Homebrew, and GNU Make — then hands off to `gmake`.

### Existing machine

```bash
gmake help         # See all available targets
gmake all          # Full setup (bootstrap + packages + dotfiles + tools + macOS defaults)
gmake dotfiles     # Deploy dotfiles only (symlinks via Tuckr)
```

> **Always use `gmake`**, not `make`. macOS ships GNU Make 3.81 (2006) — Homebrew provides the current version as `gmake`.

## Installation Profiles

```bash
gmake packages-common        # Core tools for all machines
gmake packages-private       # Personal productivity tools
gmake packages-work          # Work tools (includes common)
gmake packages-entertainment # Games and media
gmake packages-work-optional # Optional work utilities
gmake everything             # All profiles combined
```

## Dotfile Management

Dotfiles live in `Configs/<group>/` and are deployed as symlinks to `$HOME` via [Tuckr](https://github.com/RaphGL/Tuckr).

```bash
gmake dotfiles        # Deploy all groups
gmake dotfiles-rm     # Remove all symlinks
gmake status          # Show deployment state
gmake zsh             # Deploy only the zsh group
gmake neovim          # Deploy only neovim
```

## macOS Defaults

```bash
gmake macos           # Apply all defaults
gmake macos-security  # Firewall + security only
gmake macos-finder    # Finder prefs only
gmake macos-dock      # Dock + Mission Control only
# ... see gmake help for all macos-* targets
```

## System Setup (interactive)

```bash
gmake system-hosts         # Apply /etc/hosts blocklist
gmake system-git-identity  # Set git name + email
gmake system-computer-name # Set hostname
gmake system-wallpaper     # Set desktop wallpaper
```

## Package Management

`packages.json` is the single source of truth. Edit it, then regenerate `Brewfile`:

```bash
gmake brewfile   # Regenerate Brewfile from packages.json
gmake update     # brew update + upgrade + cleanup
```

Never edit `Brewfile` directly — it's a generated artifact.

## Adding Dotfiles

Create the file under the matching group in `Configs/`:

```
Configs/zsh/.zshrc          →  ~/.zshrc
Configs/git/.gitconfig      →  ~/.gitconfig
Configs/neovim/.config/nvim →  ~/.config/nvim
```

Then run `gmake dotfiles` (or `gmake <group>`) to deploy.

## License

ISC
