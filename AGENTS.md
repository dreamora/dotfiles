# AGENTS.md - Agentic Coding Guidelines

This document provides guidelines for AI coding agents working in this dotfiles repository.

## Project Overview

A **macOS dotfiles and system configuration automation project** that automates development environment setup using **Tuckr** (dotfile manager) and **GNU Make** (orchestration). Covers shell configuration (ZSH/Oh-My-Zsh/Powerlevel10k), editor configs (Vim, Neovim/LazyVim), Git workflows, and Homebrew package management.

## Repository Structure

```
.dotfiles/
├── bootstrap.sh           # Bootstrap script for fresh machines (installs Homebrew + gmake, then hands off)
├── Makefile               # Root orchestrator — include make/*.mk, profile targets
├── make/                  # Make include files (one per concern)
│   ├── bootstrap.mk       # Xcode CLT, Homebrew, core deps (tuckr, jq, gmake)
│   ├── tuckr.mk           # Dotfile deployment via tuckr (set/unset/status)
│   ├── tools.mk           # Tool setup (zsh, git, vim, node, asdf, fonts)
│   ├── packages.mk        # Profile-based Homebrew package installation
│   ├── system.mk          # Interactive/destructive system targets (hosts, identity, wallpaper)
│   └── macos.mk           # macOS defaults (security, UI, Finder, Dock, Safari, etc.)
├── Brewfile               # Generated artifact — gmake brewfile regenerates from packages.json
├── packages.json          # Source of truth for all packages — 6 keys: taps, common, private, entertainment, work, work-optional
├── Configs/               # Tuckr dotfile groups — each subdir is a group
│   ├── zsh/               # → ~/.zshrc, ~/.shellaliases, ~/.shellfn, ~/.shellvars, ~/.shellpaths
│   ├── git/               # → ~/.gitconfig, ~/.gitignore, ~/.gitmessage, ~/.git_template/
│   ├── vim/               # → ~/.vim/, ~/.vimrc
│   ├── neovim/            # → ~/.config/nvim/ (full LazyVim config)
│   ├── tmux/              # → ~/.tmux.conf
│   ├── screen/            # → ~/.screenrc
│   ├── ruby/              # → ~/.gemrc, ~/.irbrc
│   ├── node/              # → ~/.npmrc
│   ├── asdf/              # → ~/.asdfrc, ~/.tool-versions
│   └── crontab/           # → ~/.crontab
├── Hooks/                 # Tuckr hooks (run pre/post deploy per group)
│   └── neovim/pre.sh      # mkdir -p ~/.config before neovim group deploys
├── lib_sh/                # Shell helper libraries (sourced by Make targets)
│   ├── echos.sh           # Colorized output: bot, running, ok, action, warn, error
│   ├── requirers.sh       # Idempotent package installers: require_brew, require_cask, etc.
│   └── asdf_setup.sh      # ASDF plugin setup
├── Configs/hosts          # /etc/hosts blocklist (applied via gmake system-hosts)
├── scripts/               # Utility scripts (setup-githooks.sh, restore.sh, etc.)
└── .beads/                # Beads issue tracker database (bd CLI)
```

## Essential Commands

```bash
# Fresh machine setup
./bootstrap.sh             # Install Xcode CLT + Homebrew + GNU Make, then calls gmake

# Day-to-day (always use gmake, NOT make — macOS ships 2006 GNU Make 3.81)
gmake help                 # Show all available targets with descriptions
gmake all                  # Full setup: bootstrap + common packages + dotfiles + tools + macos
gmake dotfiles             # Deploy all Tuckr groups (symlinks → Configs/)
gmake status               # tuckr status: show all group deployment state

# Profile-based package installation
gmake packages-common      # Install packages available to all profiles
gmake packages-private     # Install personal/productivity packages
gmake packages-work        # Install work packages (includes common)
gmake packages-entertainment  # Install games/media packages
gmake packages-work-optional  # Install optional work tools
gmake everything           # Install ALL profiles combined

# macOS defaults
gmake macos                # Apply all macOS system defaults
gmake macos-security       # Security/firewall settings only
gmake macos-finder         # Finder preferences only
gmake macos-dock           # Dock & Mission Control only
# ... (see gmake help for all macos-* targets)

# System (interactive/destructive — prompt before applying)
gmake system-hosts         # Apply /etc/hosts blocklist (prompts for confirmation)
gmake system-git-identity  # Set git name/email interactively
gmake system-wallpaper     # Set desktop wallpaper (prompts)
gmake system-computer-name # Set hostname/ComputerName

# Dotfile management
gmake dotfiles-rm          # Remove all tuckr symlinks
gmake zsh                  # Deploy only the zsh group
gmake neovim               # Deploy only the neovim group
# (individual group targets available for all 10 groups)

# Maintenance
gmake brewfile             # Regenerate Brewfile from packages.json
gmake update               # brew update + upgrade + cleanup
```

## Issue Tracking (Beads)

This repo uses **Beads** (`bd`) for AI-native issue tracking. Always use it.

```bash
bd list                    # List all open issues
bd ready                   # Show unblocked issues ready to work
bd create "title" -p 1 -t task  # Create an issue (priority 1-5, types: task/bug/feature/epic)
bd show <id>               # Show issue details
bd update <id> --status in_progress  # Mark work started
bd close <id>              # Mark complete
bd sync                    # Sync to git (run before push)
```

**Workflow:**
1. `bd ready` — find unblocked work
2. `bd update <id> --status in_progress` — claim it
3. Do the work
4. `bd close <id>` — mark done
5. `bd sync` before `git push`

## Tuckr Concepts

- **Groups**: Directories in `Configs/` — each deploys its entire subtree as symlinks to `$HOME`
- **Hooks**: Scripts in `Hooks/<group>/pre.sh` or `post.sh` — run around group deployment
- **Commands**: `tuckr set '*'` (deploy all), `tuckr unset '*'` (remove all), `tuckr status` (check)
- **No profiles in tuckr**: We use a single repo with all groups; profiles are handled via `packages.json` + Make targets

## Make Conventions

```makefile
SHELL := /bin/bash
DOTFILES_DIR := $(shell git rev-parse --show-toplevel)
HELPERS := source $(DOTFILES_DIR)/lib_sh/echos.sh && source $(DOTFILES_DIR)/lib_sh/requirers.sh
SENTINEL_DIR := .make  # Sentinel files for slow idempotent ops

# Self-documenting targets (shown by gmake help):
## target-name: deps  ## Description shown in help
.PHONY: target-name
target-name:
	@$(HELPERS) && bot "Section header..."
	@$(HELPERS) && running "Doing thing"
	some-command
	@$(HELPERS) && ok
```

**Idempotency strategy:**
- Sentinel files in `.make/` for slow one-time ops (Xcode install, git submodule init)
- Runtime checks (`command -v`, `brew list`) for fast ops
- All targets safe to re-run

## Output Helpers (lib_sh/echos.sh)

```bash
bot "Starting section..."     # Green robot announcement  
running "Installing package"  # Yellow running indicator
ok                            # Green [ok] confirmation
action "Performing action"    # Yellow [action] header
warn "Warning message"        # Yellow [warning]
error "Error message"         # Red [error]
```

## Package Management

`packages.json` is the **single source of truth**. Structure:

```json
{
  "taps": [...],           // Homebrew taps (applied first)
  "common": { "brew": [], "cask": [], "mas": {}, "vscode": [] },
  "private": { ... },      // Personal productivity tools
  "entertainment": { ... }, // Games, media apps only
  "work": { ... },         // Work tools (installs common first)
  "work-optional": { ... } // Optional work utilities
}
```

**Never edit `Brewfile` directly** — it's generated via `gmake brewfile`.

**Drift audit** — before committing package changes, diff installed vs declared with `comm` + `jq`:

```bash
# brew formulae gap
comm -23 <(brew leaves --installed-on-request | sort) <(jq -r '.. | objects | .brew[]? | .name' packages.json | sort)
# cask gap
comm -23 <(brew list --cask | sort) <(jq -r '.. | objects | .cask[]? | .name' packages.json | sort)
# npm global gap
comm -23 <(npm list -g --depth=0 | tail -n +2 | sed 's/.*── //' | sed 's/@[0-9].*//' | sort) <(jq -r '.. | objects | .npm[]?' packages.json | sort)
```

Skip intentional non-entries: `stow` (replaced by Tuckr), `corepack`/`npm` (Node.js built-ins), `docker` (alias for `docker-desktop`). See [`docs/solutions/developer-experience/sync-packages-json-with-brew-npm-dotfiles-20260227.md`](docs/solutions/developer-experience/sync-packages-json-with-brew-npm-dotfiles-20260227.md).

## Code Style

### Shell Scripts (Bash)

```bash
#!/usr/bin/env bash
source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh
```

### Makefile Style

- 2-space indentation for recipes (tabs required by Make — editor must use real tabs in Makefiles)
- Self-documenting `## Description` comments on all public targets
- Group related targets in separate `make/*.mk` files
- Use `@` prefix to suppress echoing, `-` prefix to ignore errors where safe

### Lua (Neovim - stylua.toml)
- **Indentation**: 2 spaces
- **Line width**: 120 characters
- **Quotes**: Single (forced)
- **Call parentheses**: Always use

## Git Conventions

### Commit Messages (Conventional Commits)

```bash
git feat "message"       # feat: message
git fix "message"        # fix: message
git docs "message"       # docs: message
git chore "message"      # chore: message
git refactor "message"   # refactor: message
git build "message"      # build: message
git wip "message"        # wip: message
```

With scope: `git feat -s scope "message"` → `feat(scope): message`

### Branch/Push Settings
- Default branch: `main`
- Pull: Rebase with autostash (`git up`)
- Push: Simple (current branch only)

## Naming Conventions

- Shell scripts: `snake_case.sh`
- Make includes: `concern.mk` in `make/`
- Tuckr groups: lowercase, matches tool name (`zsh`, `git`, `neovim`)
- Config files: Standard dotfile names (`.gitconfig`, `.zshrc`, etc.)

## Important Notes

1. **Always use `gmake`** — never `make` (macOS ships GNU Make 3.81 from 2006)
2. **Idempotent**: All `gmake` targets are safe to re-run
3. **Tuckr groups**: Adding a new dotfile = create `Configs/<group>/path/to/file` matching `$HOME` structure
4. **Submodules**: oh-my-zsh, z-zsh, and Vundle are git submodules — initialized by `make/bootstrap.mk`
5. **Brewfile**: Generated artifact — edit `packages.json`, run `gmake brewfile`

## Landing the Plane (Session Completion)

**When ending a work session**, complete ALL steps. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** — `bd create "title" -p 1 -t task`
2. **Run quality gates** — `shellcheck` on changed scripts, `gmake -n` dry-run
3. **Update issue status** — close finished, update in-progress
4. **PUSH TO REMOTE** — MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** — clear stashes, prune remote branches
6. **Verify** — all changes committed AND pushed
7. **Hand off** — provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing — that leaves work stranded locally
- NEVER say "ready to push when you are" — YOU must push
- If push fails, resolve and retry until it succeeds
- Always include `.serena/` files in commits when they are added or modified

## Agent Learnings

- Before committing package changes, run the `comm`+`jq` drift audit for brew, cask, and npm globals to catch silent divergence between installed tools and `packages.json`. Skip intentional non-entries: `stow` (Tuckr replaced it), `corepack`/`npm` (Node.js built-ins), `docker` (alias for `docker-desktop`). See `docs/solutions/developer-experience/sync-packages-json-with-brew-npm-dotfiles-20260227.md`.
