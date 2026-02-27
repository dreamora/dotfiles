# context.md — Agent-Native Context

> Machine-readable reference for AI coding agents. Keep this file updated as the setup evolves.

## What This Repo Does

Automates macOS development environment setup via:
- **Tuckr** — deploys dotfiles as symlinks from `Configs/` to `$HOME`
- **GNU Make** (`gmake`) — orchestrates all installation, configuration, and maintenance

Entry point for fresh machines: `./bootstrap.sh`
Entry point for existing setups: `gmake help`

---

## Architecture Decisions (Locked)

| Decision | Choice | Reason |
|---|---|---|
| Dotfile manager | Tuckr (not GNU Stow) | Groups, hooks, simpler mental model |
| Orchestrator | Single `Makefile` + `make/*.mk` includes | Composable, self-documenting, agent-friendly |
| Package source of truth | `packages.json` | Single file drives all profile installations |
| Brewfile | Generated artifact via `gmake brewfile` | Never edit directly |
| Profile strategy | `packages.json` profiles + Make targets | No separate repos or tuckr profiles |
| macOS defaults | `make/macos.mk` individual targets | Granular, composable, skippable |
| Idempotency | Sentinel files (`.make/`) for slow ops; runtime checks for fast ops | All targets safe to re-run |
| Make version | `gmake` (GNU Make 4.x via Homebrew) | macOS ships 2006 v3.81 — never use `make` |

---

## Tuckr Groups (10 total)

Each directory under `Configs/` is a Tuckr group. Running `tuckr set <group>` creates symlinks mirroring the group's subtree into `$HOME`.

| Group | Configs path | Deploys to |
|---|---|---|
| `zsh` | `Configs/zsh/` | `~/.zshrc`, `~/.shellaliases`, `~/.shellfn`, `~/.shellvars`, `~/.shellpaths` |
| `git` | `Configs/git/` | `~/.gitconfig`, `~/.gitignore`, `~/.gitmessage`, `~/.git_template/` |
| `vim` | `Configs/vim/` | `~/.vim/`, `~/.vimrc` |
| `neovim` | `Configs/neovim/` | `~/.config/nvim/` (full LazyVim config) |
| `tmux` | `Configs/tmux/` | `~/.tmux.conf` |
| `screen` | `Configs/screen/` | `~/.screenrc` |
| `ruby` | `Configs/ruby/` | `~/.gemrc`, `~/.irbrc` |
| `node` | `Configs/node/` | `~/.npmrc` |
| `asdf` | `Configs/asdf/` | `~/.asdfrc`, `~/.tool-versions` |
| `crontab` | `Configs/crontab/` | `~/.crontab` |

**Hooks**: `Hooks/neovim/pre.sh` — runs `mkdir -p ~/.config` before neovim group deploys.

---

## Make Targets Reference

### Top-level (Makefile)

| Target | Description |
|---|---|
| `gmake all` | Full setup: bootstrap → packages-common → dotfiles → tools → macos |
| `gmake dotfiles` | Deploy all Tuckr groups |
| `gmake status` | Show Tuckr deployment state for all groups |
| `gmake brewfile` | Regenerate `Brewfile` from `packages.json` |
| `gmake update` | `brew update && brew upgrade && brew cleanup` |
| `gmake help` | Show all targets with descriptions |

### make/packages.mk — Profile Installation

| Target | Installs |
|---|---|
| `gmake packages-common` | Taps + common brew/cask/mas/vscode |
| `gmake packages-private` | Personal productivity tools |
| `gmake packages-entertainment` | Games and media apps only |
| `gmake packages-work` | Work tools (runs common first) |
| `gmake packages-work-optional` | Optional work utilities |
| `gmake everything` | All profiles combined |

### make/macos.mk — macOS Defaults (all composable)

| Target | Scope |
|---|---|
| `gmake macos` | All defaults (calls all sub-targets) |
| `gmake macos-security` | Firewall, remote access, login security |
| `gmake macos-ssd` | Hibernation, sleep image, motion sensor |
| `gmake macos-ui` | Menu bar, save dialogs, system-wide UI |
| `gmake macos-input` | Trackpad, keyboard, Bluetooth |
| `gmake macos-screen` | Screenshots, screensaver, HiDPI |
| `gmake macos-finder` | Finder prefs, view modes, spring loading |
| `gmake macos-dock` | Dock size, animation, Mission Control |
| `gmake macos-safari` | Safari/WebKit developer settings |
| `gmake macos-mail` | Mail.app threading and shortcuts |
| `gmake macos-spotlight` | Spotlight indexing categories |
| `gmake macos-terminal` | Terminal focus-follows-mouse |
| `gmake macos-timemachine` | Disable TM auto-prompts and local backups |
| `gmake macos-activity` | Activity Monitor display settings |
| `gmake macos-apps` | TextEdit, Disk Utility, App Store debug menus |
| `gmake macos-messages` | Messages emoji/quote substitution |
| `gmake macos-kill` | Kill affected apps so changes take effect |

### make/system.mk — Interactive / Destructive (prompt before applying)

| Target | Description |
|---|---|
| `gmake system-hosts` | Apply `/etc/hosts` blocklist (prompts) |
| `gmake system-git-identity` | Set git name/email interactively |
| `gmake system-wallpaper` | Set desktop wallpaper (prompts) |
| `gmake system-computer-name` | Set ComputerName/HostName (prompts) |

### make/tuckr.mk — Dotfile Deployment

| Target | Description |
|---|---|
| `gmake dotfiles` | `tuckr set '*'` — deploy all groups |
| `gmake dotfiles-rm` | `tuckr unset '*'` — remove all symlinks |
| `gmake status` | `tuckr status` — show group state |
| `gmake zsh` | Deploy only the `zsh` group |
| `gmake neovim` | Deploy only the `neovim` group |
| `gmake git` | Deploy only the `git` group |
| *(etc.)* | One target per group for selective deployment |

---

## Package Profiles (packages.json)

```
packages.json
├── taps          — Homebrew taps (added before anything else)
├── common        — Installed on all machines (brew, cask, mas, vscode)
├── private       — Personal productivity tools
├── entertainment — Games and media apps only
├── work          — Work tools (always installs common first)
└── work-optional — Optional work utilities
```

**Rule**: Edit `packages.json`, then run `gmake brewfile` to regenerate `Brewfile`. Never edit `Brewfile` directly.

---

## Key File Locations

| File | Purpose |
|---|---|
| `Makefile` | Root orchestrator, includes all `make/*.mk` |
| `bootstrap.sh` | Fresh machine entry point (Xcode CLT → Homebrew → gmake) |
| `packages.json` | Single source of truth for all packages |
| `Brewfile` | Generated from `packages.json` — never edit manually |
| `lib_sh/echos.sh` | `bot`, `running`, `ok`, `action`, `warn`, `error` output helpers |
| `lib_sh/requirers.sh` | `require_brew`, `require_cask`, `require_mas`, etc. |
| `lib_sh/asdf_setup.sh` | ASDF plugin setup helpers |
| `Configs/hosts` | `/etc/hosts` blocklist (applied by `gmake system-hosts`) |
| `.make/` | Sentinel directory for idempotent slow ops (gitignored) |
| `.beads/` | Beads issue tracker database |

---

## Submodules

| Submodule | Path | Purpose |
|---|---|---|
| oh-my-zsh | `Configs/zsh/oh-my-zsh` | ZSH framework |
| z (jump around) | `Configs/zsh/z-zsh` | Directory jumping |
| Vundle | `Configs/vim/.vim/bundle/Vundle.vim` | Vim plugin manager |

Initialized by `make/bootstrap.mk` using sentinel files in `.make/`.

---

## Idempotency Patterns

```makefile
# Slow one-time ops: sentinel file gate
.make/xcode-clt:
    xcode-select --install
    touch .make/xcode-clt

# Fast ops: runtime check
tool-zsh:
    @if ! grep -q "$(HOMEBREW_PREFIX)/bin/zsh" /etc/shells; then \
        sudo sh -c "echo $(HOMEBREW_PREFIX)/bin/zsh >> /etc/shells"; \
    fi
```

---

## Adding New Dotfiles

1. Create the file at `Configs/<group>/<path/matching/$HOME/structure>`
2. Run `gmake dotfiles` (or `gmake <group>`) to deploy
3. Tuckr creates the symlink automatically

Example: to add `~/.wezterm.lua`:
```
Configs/wezterm/.wezterm.lua   →  deployed as  ~/.wezterm.lua
```

## Adding a New Tuckr Group

1. Create `Configs/<newgroup>/` with files
2. Add `gmake <newgroup>` target to `make/tuckr.mk`
3. Run `gmake <newgroup>` to deploy
