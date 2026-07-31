# `.dotfiles` — Marc's executable macOS workstation

> **Forked from [atomantic/dotfiles](https://github.com/atomantic/dotfiles).**  
> This is a personal fork that has diverged significantly — see [History](#history).

This repository is my executable macOS workstation definition. Its purpose is to
make a new or existing Mac converge on the same development environment while
keeping that environment reviewable, repeatable, and recoverable in Git.

[![Syntax Gate](https://github.com/dreamora/dotfiles/actions/workflows/syntax-gate.yml/badge.svg)](https://github.com/dreamora/dotfiles/actions/workflows/syntax-gate.yml)
[![Reliability Gates](https://github.com/dreamora/dotfiles/actions/workflows/reliability-gates.yml/badge.svg)](https://github.com/dreamora/dotfiles/actions/workflows/reliability-gates.yml)
[![Bootstrap CI](https://github.com/dreamora/dotfiles/actions/workflows/bootstrap.yml/badge.svg)](https://github.com/dreamora/dotfiles/actions/workflows/bootstrap.yml)

---

## Architecture

```
software manifests + managed configuration
                  |
                  v
              install.sh
                  |
        +---------+----------+
        |         |          |
     Homebrew    mise      GNU Stow
                              |
                    +---------+----------+
                    |         |          |
                  $HOME   ~/.config  ~/.local/bin
```

The installer combines five responsibilities:

1. **Machine bootstrap** — Xcode CLT, Homebrew, GNU Stow, zsh, fonts.
2. **Runtime management** — [mise](https://mise.jdx.dev) installs and activates
   Node.js, Python, Bun, and other runtimes. No nvm, pyenv, nodenv, or asdf.
3. **Package policy** — `software/*.list` files define common, private, and
   business package profiles. `install_packages.sh` resolves and installs them.
4. **Managed configuration** — dotfiles in `homedir/` are stowed to `$HOME`,
   configs in `config/` go to `~/.config`, scripts in `scripts/` go to
   `~/.local/bin`.
5. **System customization** — optional macOS defaults (firewall, Finder, Dock,
   keyboard, trackpad, screenshots, Energy Saver, etc.).

## Shell

Zsh with **Starship prompt** (replaced Powerlevel10k). No Oh My Zsh. Fast init:

- Hand-rolled `.zshrc` (~80 lines)
- Cached `compinit` (24-hour recheck)
- Fzf, zoxide, mise, atuin, Starship — all guarded by `command -v`
- Two zsh plugins from Homebrew: `zsh-autosuggestions`, `zsh-syntax-highlighting`

## Package Manifests

Packages are declared in `software/*.list` — one package per line, `#` comments
allowed. Three profiles stack on top of the common set:

| Profile   | Role                          | Directory              |
|-----------|-------------------------------|------------------------|
| Common    | Every machine                 | `software/`            |
| Private   | Personal devices              | `software/private/`    |
| Business  | Work machines                 | `software/business/`   |

### Package types tracked

| File            | Manager              | Notes                         |
|-----------------|----------------------|-------------------------------|
| `tap.list`      | `brew tap`           | Homebrew taps                 |
| `bootstrap.list`| `brew install`       | Pre-stow formulae             |
| `brew.list`     | `brew install`       | Formulae                      |
| `cask.list`     | `brew install --cask`| Desktop apps                  |
| `npm.list`      | `npm install -g`     | Global npm packages            |
| `gem.list`      | `gem install`        | Ruby gems                     |
| `mas.list`      | `mas install`        | Mac App Store apps             |
| `vscode.list`   | `code --install-extension`| VS Code extensions         |

See [software/README.md](./software/README.md) for line format details.

## Editors & Tools

- **Neovim** — LazyVim configuration under `nvim/`
- **Zed** — primary editor on macOS, config via `homedir/.config/zed/`
- **Git** — conventional commit aliases, VS Code as diff/merge tool, `gh`
  credential helper. See [AGENTS.md](./AGENTS.md) for full git conventions.

## Installation

> ☢️ **Review what the script does before running it.** You are responsible for
> everything this script does to your machine (see [LICENSE](./LICENSE.md)).

```bash
git clone --recurse-submodules git@github.com:dreamora/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh       # Run from Terminal.app, not iTerm
```

The installer is **idempotent** — you can run it again as you add features.

To install packages only (after stow has linked the dotfiles):

```bash
./install_packages.sh          # Combined profile (common + private + business)
./install_packages.sh private  # Private overlay only
./install_packages.sh business # Business overlay only
```

### Restoring backed-up dotfiles

Existing dotfiles are backed up to `~/.dotfiles_backup/$(date)` before being
replaced. Restore with:

```bash
./restore.sh 2026.07.30.12.00.00   # Use the backup folder name
```

The restore script only replaces dotfiles — it does not undo system settings.

## CI

Three GitHub Actions workflows verify every push and pull request to `main`:

| Workflow           | Checks                                      |
|--------------------|---------------------------------------------|
| **Syntax Gate**    | `bash -n`, `zsh -n`, manifest validation    |
| **Reliability**    | ShellCheck, stow symlink verify, manifests  |
| **Bootstrap**      | Full `install.sh` on `macos-15`/`macos-26`  |

## History

This repo started as [atomantic/dotfiles](https://github.com/atomantic/dotfiles)
and has been actively forked and modernized. Major milestones beyond the
upstream:

- **2025–2026** — Stripped Oh My Zsh (~25 plugins + Powerlevel10k) → hand-rolled
  zsh + Starship. Replaced nvm/pyenv/nodenv/asdf with mise. Replaced ag → ripgrep,
  autojump → zoxide, ccat → bat, ls → eza. Moved from Brewfile to `.list` manifests
  with profile overlays. Added CI (syntax gate, shellcheck, bootstrap). Split package
  declarations into common/private/business profiles.

## License

ISC — see [LICENSE.md](./LICENSE.md). Upstream (c) 2015 Adam Eivy.