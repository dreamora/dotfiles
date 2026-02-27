# macOS Dotfiles

Automated macOS development environment setup using **Tuckr** for dotfile deployment and **GNU Make** as the orchestration layer.

## What this branch changed

This branch completed the migration from legacy install scripts to a modular, testable workflow:

- Consolidated setup into `bootstrap.sh` + `Makefile` + `make/*.mk` include files
- Migrated dotfiles into Tuckr groups under `configs/` (replacing old `homedir/` + standalone `nvim/` layout)
- Added preflight, dry-run, verify, backup, and rollback flows for safer dotfile deployment
- Added profile-based package management in `packages.json` with generated `Brewfile`
- Added role/policy/secrets/drift/audit tooling for safer automation and shared-machine operation
- Added a test harness in `tests/` and CI workflow in `.github/workflows/test.yml` (quick suite on `macos-15`)

## What's included

- **Shell**: ZSH + Oh-My-Zsh + Powerlevel10k
- **Editors**: Vim (Vundle) + Neovim (LazyVim)
- **Git**: Aliases, templates, hooks, conventional commit helpers
- **Tooling**: asdf, tmux, screen, Node.js, Ruby, GNU Make, Tuckr
- **System config**: macOS defaults targets + interactive system setup targets
- **Packages**: Profile-based install model (`common`, `private`, `work`, `entertainment`, `work-optional`)

## Quick Start

### Fresh machine

```bash
git clone --recurse-submodules https://github.com/marcboeker/dotfiles ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs Xcode Command Line Tools, Homebrew, and GNU Make, then hands off to `gmake`.

### Existing machine

```bash
gmake help
gmake all
gmake dotfiles
```

> Always use `gmake`, not `make`.

## Core Commands

```bash
gmake all             # bootstrap + dotfiles + tools
gmake setup           # all + common package profile
gmake work            # setup + work profile
gmake private         # setup + private profile
gmake entertainment   # setup + entertainment profile
gmake everything      # setup + all package profiles
gmake status          # tuckr status
gmake test            # quick non-destructive test harness
```

## Dotfile Management

Dotfiles are grouped under `configs/<group>/` and deployed as symlinks to `$HOME` by Tuckr.

Current groups:

- `zsh`, `git`, `vim`, `neovim`, `tmux`, `screen`, `ruby`, `node`, `asdf`, `crontab`

Commands:

```bash
gmake dotfiles           # deploy all groups
gmake dotfiles-dryrun    # preview deployment
gmake dotfiles-preflight # conflict/prereq checks
gmake dotfiles-verify    # verify all groups are symlinked
gmake dotfiles-rm        # remove all symlinks
gmake neovim             # deploy one group
```

## Package Profiles

`packages.json` is the source of truth. `Brewfile` is generated.

```bash
gmake packages-common
gmake packages-private
gmake packages-work
gmake packages-entertainment
gmake packages-work-optional
gmake brewfile
```

Never edit `Brewfile` directly.

## Personalization

### 1) Add or remove software

Edit `packages.json` in the relevant profile and regenerate:

```bash
gmake brewfile
```

Then install with the matching target (for example `gmake packages-work`).

### 2) Customize dotfiles

Add/edit files in the matching `configs/<group>/` subtree. Path structure mirrors `$HOME`.

Examples:

```text
configs/zsh/.zshrc            -> ~/.zshrc
configs/git/.gitconfig        -> ~/.gitconfig
configs/neovim/.config/nvim   -> ~/.config/nvim
```

Deploy with `gmake <group>` or `gmake dotfiles`.

### 3) Set machine role

Roles supported: `personal`, `work`, `shared`.

```bash
gmake role
gmake role-set ROLE=work
gmake role-apply
gmake policy-check
gmake policy-report
```

Role resolution order: `ROLE=` override -> `DOTFILES_ROLE` env -> `~/.dotfiles_role` -> hostname heuristic -> `personal`.

### 4) Secrets setup (SOPS + age)

```bash
gmake secrets-setup
gmake secrets-status
gmake secrets-edit FILE=secrets/myapp.sops.env
gmake secrets-decrypt FILE=secrets/myapp.sops.env OUT=/tmp/myapp.env
```

## Expansion Guide

### Add a new dotfile group

1. Create `configs/<new-group>/...` with `$HOME`-mirrored paths
2. Add the group name to `TUCKR_GROUPS` in `make/tuckr.mk`
3. (Optional) Add hook scripts in `Hooks/<new-group>/pre.sh` or `post.sh`
4. Validate and deploy:

```bash
gmake dotfiles-dryrun
gmake <new-group>
gmake dotfiles-verify
```

### Add a new package profile

1. Add profile structure in `packages.json`
2. Add install target wiring in `make/packages.mk` and root `Makefile` profile composition
3. Regenerate Brewfile and test:

```bash
gmake brewfile
gmake test
```

### Add a new Make concern

1. Create `make/<concern>.mk`
2. Add `include make/<concern>.mk` to `Makefile`
3. Add documented targets (`## description`) so they appear in `gmake help`

## Safety and Verification

```bash
gmake test            # quick CI-safe test harness
gmake test-full       # local full suite (requires deployed dotfiles)
gmake drift           # declared vs installed drift report
gmake drift-gate      # fail on critical drift
gmake audit-log       # recent audit entries
gmake audit-summary   # summarized destructive operations
gmake backup-list     # list backup snapshots
```

## Shared Machine / CI Modes

```bash
DOTFILES_SHARED_MACHINE=1 gmake setup
DOTFILES_NONINTERACTIVE=1 gmake test
```

- `DOTFILES_SHARED_MACHINE=1` enables shared-machine guard rails
- `DOTFILES_NONINTERACTIVE=1` disables prompts for automation/CI

## License

ISC
