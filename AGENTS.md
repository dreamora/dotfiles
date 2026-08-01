# AGENTS.md - Agentic Coding Guidelines

This document provides guidelines for AI coding agents working in this dotfiles repository.

**Mandatory maintenance reference:** Before changing `install.sh`, package
manifests, shell startup or `PATH`, the Stow layout, or CI, read
`docs/reference/dotfiles-maintenance.md`. It is the canonical record of verified
architecture, decisions, validation boundaries, and known installer/idempotency
limitations. Update it in the same change whenever those contracts change. The
existence of bootstrap CI does not establish full reproducibility or idempotency;
do not infer either from it.

## What This Project Is

This repository is Marc's executable macOS workstation definition. It is not an
application or reusable library. Its purpose is to make a new or existing Mac
converge on the same development environment while keeping that environment
reviewable, repeatable, and recoverable in Git.

The project combines five responsibilities:

1. **Machine bootstrap**: `install.sh` installs bootstrap dependencies, prepares
   Homebrew and GNU Stow, links configuration, installs runtimes and packages,
   and optionally applies macOS preferences.
2. **Package policy**: `software/*.list` defines common, private, and business
   package profiles. `install_packages.sh` resolves and installs those profiles.
3. **Managed user configuration**: `homedir/`, `config/`, and `scripts/` are
   source trees for files installed into `$HOME`, `~/.config`, and
   `~/.local/bin`.
4. **Development-tool configuration**: shell, Git, Vim/Neovim, mise, Starship,
   zoxide, terminal tools, and agent tooling live here so workstation behavior
   can be reproduced from the repository.
5. **System customization and recovery**: the installer manages selected macOS
   defaults and provides restore tooling, but general pre-Stow backup creation is
   not currently implemented or verified.

`homedir/.claude/`, `homedir/.codex/`, and `homedir/.gstack/` represent global
user-level tool configuration, like other dotfiles under `homedir/`; they are
not repository-local runtime directories. Track intentional, portable
configuration there. Keep generated sessions, caches, credentials, telemetry,
and security reports out of Git.

The main provisioning flow is:

```text
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

Treat installer changes as workstation-migration changes, not ordinary script
cleanup. Preserve idempotency, existing-machine safety, explicit consent for
system-level changes, and fresh-machine behavior.

## Key Repository Mapping

This repository separates user-facing files by their target location:

- `homedir/`: files managed in `$HOME` through GNU Stow.
- `config/`: files managed under `~/.config`; link contained app directories
  or files individually instead of replacing the whole `~/.config` directory.
- `scripts/`: executable utilities intended to be available as global shell commands.

## Repository Structure

```
.dotfiles/
├── install.sh             # Main installation script
├── install_packages.sh    # Software manifest installer
├── software/              # Package manifests (common/private/business)
├── config/                # App configs stowed under ~/.config
│   └── starship.toml      # Starship prompt configuration
├── homedir/               # Dotfiles symlinked to ~ via GNU stow
│   ├── .gitconfig         # Git configuration
│   ├── .zshrc             # ZSH configuration
│   ├── .shellaliases      # Shell aliases
│   ├── .shellfn           # Shell functions
│   ├── .shellvars         # Shell variables
│   └── .shellpaths        # PATH configuration
├── lib_sh/                # Shell helper libraries
│   ├── echos.sh           # Colorized output helpers
│   ├── requirers.sh       # Package requirement functions
│   └── mise_setup.sh      # Mise runtime setup
├── nvim/                  # Neovim/LazyVim configuration
│   └── lua/               # Lua plugin configurations
├── configs/               # App configurations (iTerm, hosts)
├── scripts/               # Global utility shell scripts, including completion refresh
└── docs/reference/       # Durable operational references and maintenance contracts
```

## Build/Install Commands

```bash
./install.sh               # Full system setup (run from Terminal, not iTerm)
./install.sh ./software     # Full setup with an explicit software manifest directory
./install_packages.sh          # Current combined default (common + private + business); deliberate union/testing only
./install_packages.sh private  # Install common + private packages
./install_packages.sh business # Install common + business packages
npm install                # Install Node.js dependencies
```

### Testing

This project has no formal test suite. The `npm test` command is not implemented.

### Documented Solutions

`docs/reference/` contains durable operational references for repository
maintenance. Consult the relevant reference when implementing or debugging in a
documented area. `.compound-engineering/solutions/` is ignored and is not a
source of tracked repository guidance.

### Linting

```bash
shellcheck <script.sh>     # Lint shell scripts (installed via Homebrew)
eslint <file.js>           # Lint JavaScript files
stylua nvim/               # Format Lua files for Neovim
```

## Code Style Guidelines

### General Formatting (.editorconfig)

- **Line endings**: Unix (LF)
- **Encoding**: UTF-8
- **Indentation**: 2 spaces (no tabs)
- **Max line length**: 150 characters
- **Trailing whitespace**: Trim
- **Final newline**: Always insert

### Shell Scripts (Bash)

#### Shebang

Always use the portable shebang:

```bash
#!/usr/bin/env bash
```

#### Sourcing Libraries

Source helper libraries at the top of scripts:

```bash
source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh
```

#### Output Helpers (lib_sh/echos.sh)

Use colorized output functions for user feedback:

```bash
bot "Starting installation..."    # Green robot announcement
running "Installing package"      # Yellow running indicator
ok                                # Green [ok] confirmation
action "Performing action"        # Yellow [action] header
warn "Warning message"            # Yellow [warning]
error "Error message"             # Red [error]
print_success "Success"           # ✔ checkmark
print_error "Failed"              # ✖ error mark
```

#### Package Requirements (lib_sh/requirers.sh)

Use helper functions for idempotent package installation:

```bash
require_brew package_name         # Install Homebrew formula
require_cask app_name             # Install Homebrew cask
require_npm package_name          # Install npm global package
require_gem gem_name              # Install Ruby gem
require_mas "App Name" app_id     # Install Mac App Store app
require_tap user/repo             # Add Homebrew tap
require_vscode extension_id       # Install VS Code extension
```

#### Software Manifests
- Keep package inventory in `software/*.list`
- Use `software/private/*.list` and `software/business/*.list` only for overlay packages
- Keep one package per line; use pipe-delimited metadata only where `software/README.md` documents it

#### Error Handling

- Check command exit status with `$?` or `${PIPESTATUS[0]}`
- Use descriptive error messages with the `error` function

#### User Prompts

```bash
read -r -p "Prompt message? [y|N] " response
if [[ $response =~ (yes|y|Y) ]]; then
  # Handle yes
fi
```

### JavaScript (Node.js)

- **Environment**: Node.js, ES6
- **No undefined variables** (`no-undef: 2`)
- **No unused local variables** (`no-unused-vars: 2`)
- **Quotes**: Single preferred but not enforced

### Lua (Neovim - stylua.toml)

- **Indentation**: 2 spaces
- **Line width**: 120 characters
- **Quotes**: Single (forced)
- **Call parentheses**: Always use

## Git Conventions

### Commit Messages (Conventional Commits)

Use git aliases for conventional commit types:

```bash
git feat "message"           # feat: message
git fix "message"            # fix: message
git docs "message"           # docs: message
git chore "message"          # chore: message
git refactor "message"       # refactor: message
git test "message"           # test: message
git style "message"          # style: message
git perf "message"           # perf: message
git build "message"          # build: message
git ci "message"             # ci: message
git wip "message"            # wip: message
```

With scope: `git feat -s scope "message"` → `feat(scope): message`
Breaking change: `git feat -a "message"` → `feat!: message`

### Useful Git Aliases

```bash
git s                        # Short status
git up                       # Pull with rebase and autostash
git d                        # Diff with color-words
git co branch                # Checkout
git cob branch               # Checkout -b (new branch)
git pwl                      # Push --force-with-lease (safe force push)
```

### Branch/Push Settings

- Default branch: `main`
- Pull: Rebase with autostash
- Push: Simple (current branch only)

## Naming Conventions

### Files

- Shell scripts: `snake_case.sh`
- Config files: Standard names (`.gitconfig`, `.zshrc`, etc.)
- Lua files: `snake_case.lua`

### Functions

- Shell: `snake_case` (e.g., `require_brew`, `print_success`)
- Lua: `snake_case`

### Variables

- Shell: `UPPER_CASE` for exports, `lower_case` for locals
- Colors: `COL_` prefix (e.g., `COL_GREEN`, `COL_RESET`)

## Symlink Management

Dotfiles in `homedir/` are symlinked to `$HOME` using GNU Stow:

```bash
stow -v -d "$HOME/.dotfiles" -t "$HOME" homedir
```

The current `install.sh`/Stow path does not create general dated backups of
displaced dotfiles. `restore.sh` works only when a compatible backup already
exists; see `docs/reference/dotfiles-maintenance.md`.

## Important Notes

1. **Validation boundary**: CI tests a limited second-run path only; do not claim full installer idempotency or fresh-machine reproducibility
2. **Run from Terminal**: Run `install.sh` from Terminal.app, not iTerm (to preserve iTerm settings)
3. **Restore**: Use `./restore.sh $DATE` only when a compatible backup already exists
4. **Submodules**: Vundle is the only remaining git submodule
