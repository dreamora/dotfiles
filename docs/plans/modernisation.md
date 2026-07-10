# Dotfiles Modernization Plan

> **Status: EXECUTED 2026-07-10** on branch `modernize-shell` (6 commits, `16dccd3..a3946b6`).
> Result: interactive startup **1.102 s → 120 ms**, login shell **1.253 s → 120 ms** (hyperfine, warmup 3, 10 runs).

## Context

The repo (GNU Stow-based) had accumulated years of layers: Oh-My-Zsh with ~25 plugins + Powerlevel10k, four overlapping version managers (nvm eager, pyenv eager, asdf plugin, mise), z + autojump both active, `compinit` run 3×, brew shellenv eval'd 2–3×, the `.shell*` files sourced twice per shell, and three overlapping package manifests (Brewfile, `software/*.list`, `packages.json`). Startup was slow and several bugs/stale entries lingered. The p10k theme directory was in fact missing, so every shell start errored before this work.

**Decisions (fixed):**
- Replace OMZ + p10k with **minimal zsh + starship**
- Consolidate version managers to **mise only**
- Tool swaps: z/autojump → **zoxide** (`--cmd j` preserves `j <dir>` muscle memory), ag → **ripgrep**, find → **fd**, fix broken eza alias
- Package manifests → **`software/*.list` as single source of truth**
- Fix bugs/stale config

Each phase was committed separately; the shell stayed usable after every commit. Rollback = `git checkout` + `stow -R`.

## Phase 0 — Baseline ✅

- `hyperfine --warmup 3 'zsh -i -c exit'`: **1.102 s ± 0.018 s** (login: 1.253 s ± 0.037 s).
- Numbers recorded in commit `16dccd3`.

## Phase 1 — Bug fixes (no architecture change) ✅ `10ce2bf`

0. First commit: pre-existing uncommitted worktree changes (BEADS_DIR fix, formatting, sentinel.md removal) — `16dccd3`.
1. `.profile` — removed stale `/Users/dreamora/.lmstudio/bin`; collapsed LM Studio PATH blocks into guarded checks.
2. `.shellpaths` — removed `export PATH=$PATH:.` (security smell). `typeset -U path PATH` added to `.zshenv` for global PATH dedupe.
3. `.shellaliases` — fixed eza guard (`[ -d "eza" ]` tested a literal directory, so eza aliases never activated) → `command -v eza`. Removed `ack=ag`. `rm` alias now a safe-rm/trash-put fallback chain instead of a double definition.
4. `.shellfn` — removed pnpm/npm auto-install side effect from `cd()`; added explicit `deps()` helper (pnpm/npm/yarn lockfile aware). `fixperms()` swapped find → fd.
5. `.tmux.conf` — dropped `reattach-to-user-namespace` (unneeded on modern tmux; formula wasn't installed): `default-command "${SHELL}"`, copy bindings pipe to `pbcopy`.
6. Untracked `nvim.log`.
7. `FZF_DEFAULT_COMMAND` → `fd --type f --hidden --follow --exclude .git`, defined once in `.shellvars`.

## Phase 2 — Install new tools ✅ `e639bc5`

Added to `software/brew.list` and installed: `starship zoxide zsh-autosuggestions zsh-completions zsh-syntax-highlighting` (brew packages, not submodules — repo is brew-centric and submodules were being removed).

## Phase 3 — Rewrite zsh startup chain ✅ `d585ee4`

Single-sourcing rule: env/PATH once (login), interactive once (`.zshrc`).

- **`.zshenv`** — `typeset -U path PATH fpath` only.
- **`.zprofile`** — one `eval "$(/opt/homebrew/bin/brew shellenv)"` + `source ~/.profile`. All Rosetta/i386 arch branches deleted (no longer needed).
- **`.profile`** — sources `.shellvars` + `.shellpaths` only (bash-compatible); private_vars, LM Studio, cargo, atuin-env guards.
- **`.shellpaths`** — absorbed every PATH export previously scattered through `.zshrc` (JetBrains, Android/JAVA_HOME, openjdk, ruby/gem static path instead of `$(gem environment gemdir)` subshell, gcloud, bun, icu4c/llvm, console-ninja, antigravity, mise shims for non-interactive shells), each added once.
- **`.zshrc`** (~80 lines) — history opts; `.shellfn` + `.shellaliases`; one **cached compinit** (`-C` unless dump >24 h); fzf (`fzf --zsh`); **zoxide** (`--cmd j`); **mise**; **atuin**; **starship**; autosuggestions; syntax-highlighting last; `bindkey -v`. Every eval guarded with `command -v` so a bare machine degrades gracefully.
- **OMZ plugin replacements:** docker/kubectl completions → static fpath + one compinit; gitfast → zsh built-in `_git`; autojump/z → zoxide; asdf → mise; rest dropped or covered by brew site-functions.
- **Static completions:** `scripts/regen-completions.sh` writes `~/.zsh/completions/_jj`, `_kubectl` — run after upgrading those tools. Removed the `source <(jj util completion zsh)` startup subshell.
- **`config/starship.toml`** (stows to `~/.config/starship.toml`): git branch/status, cmd_duration ≥2 s, python venv, nodejs, kubernetes scoped via detect_files, vi-mode-aware prompt character.
- **Git aliases declarative:** `homedir/.gitaliases` (fdr alias + fetch.prune) included from `.gitconfig`; `.init_gitaliases.sh` deleted — no more `git config --global` mutations on every shell start.
- Deleted: nvm block, OMZ vars/plugins/source, misplaced p10k instant-prompt, `.p10k.zsh`, duplicate docker compinit blocks, `cargo env.fish` bug, z.sh double-sourcing, per-prompt `z --add` precmd.
- Fixed during verification: `/opt/homebrew/share` was group-writable → compaudit failure silently aborting compinit; `chmod g-w`.

## Phase 4 — Mise consolidation ✅ (folded into `d585ee4`)

1. `homedir/.config/mise/config.toml`: node 24 (resolved 22 vs 24.15.0 mismatch toward newer), java openjdk-17, bun latest, python 3.14. `legacy_version_file = true` kept so per-project `.nvmrc`/`.tool-versions` still work.
2. Global `homedir/.tool-versions` deleted (all tools declared explicitly first).
3. `mise install` verified: node v24.15.0, python 3.14.6, java openjdk-17.0.2. Then `brew uninstall nvm pyenv asdf autojump the_silver_searcher`; `~/.nvm ~/.pyenv ~/.asdf` removed.

## Phase 5 — Submodule removal + install.sh ✅ `d2c3725`

1. `oh-my-zsh` and `z-zsh` submodules removed (deinit + `git rm` + `.git/modules` cleanup). **Vundle/legacy vim left alone** (isolated; nvim is the active editor) — future cleanup.
2. `install.sh`: p10k clone/configure block replaced with a **core shell tools** install (starship, zoxide, zsh plugins, mise, atuin, fzf, eza, bat, rg, fd, stow) that runs *before* the stow step, so a fresh machine's first zsh launch is fully functional. Belt-and-suspenders with the `command -v` guards in `.zshrc`.
3. `scripts/verify_folder_contracts.sh` run after every install.sh edit (contracts pin the stow invocations) — green.
4. CI: dead `oh-my-zsh`/`z-zsh` path excludes dropped from `reliability-gates.yml` and `syntax-gate.yml`.

## Phase 6 — Package manifest consolidation ✅ `a3946b6`

Kept **`software/*.list`** (only system `install.sh` executes; supports common/private/business profiles; covers brew/cask/tap/mas/npm/gem/vscode).

1. Ported Brewfile-only entries: brews `act beads dolt hey hugo mactop make` (skipped `node` — mise owns it); casks `anki codex copilot-cli handbrake-app iterm2 lm-studio notion notion-calendar thebrain virtualbox`; 8 mas apps; `anomalyco/tap`.
2. Dropped `autojump`, `the_silver_searcher`, `reattach-to-user-namespace`.
3. Deleted `Brewfile`, `packages.json`, `brew-deps.md`; AGENTS.md updated.
4. CI same commit: Brewfile parse step and packages.json jq check removed (manifest validation via `install_packages.sh --check combined` already existed) — green to green.

## Phase 7 — Verification ✅

- **Startup:** 120.1 ms ± 3.4 ms interactive, 119.9 ms ± 9.8 ms login (was 1.102 s / 1.253 s) — ~9× faster.
- **Functional (clean-env pty shell):** git/docker/jj/kubectl completions load; `j <dir>` works (213 entries imported from z + autojump DBs); atuin + fzf widgets bound; autosuggestions + syntax-highlighting active; vi mode on; `node -v` = v24.15.0; starship prompt active.
- **tmux:** config loads clean, `default-command /bin/zsh`, copy → pbcopy.
- **Stow:** all three packages (`homedir`, `config`, `scripts`) restow clean.
- **Gates:** folder contracts verified, shellcheck clean on install.sh, `install_packages.sh --check combined` passes, `bash -l` sanity OK (`.profile`/`.shellvars`/`.shellpaths` remain bash-compatible).

## Maintenance notes

- Run `scripts/regen-completions.sh` after upgrading jj or kubectl.
- Keep the single-sourcing rule: env/PATH in `.zprofile`/`.profile`/`.shellpaths`, interactive-only in `.zshrc`, exactly one compinit.
- Guard any new `eval "$(tool init ...)"` with `command -v tool` and keep it out of the login-shell path unless needed non-interactively.
- Do not reintroduce runtime `git config` calls in shell startup — extend `homedir/.gitaliases` instead.
- `verify_folder_contracts.sh` greps install.sh for the exact stow invocation shape — run it after touching install.sh.
