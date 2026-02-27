# Sync packages.json with installed Homebrew and npm globals

## Source

- Original: `docs/solutions/developer-experience/sync-packages-json-with-brew-npm-dotfiles-20260227.md`

## Category

- `developer-experience`

## Problem

`packages.json` (the single source of truth for all package installs) drifted from what was actually installed via Homebrew and npm. Missing formulae, casks, and npm globals were untracked, and one tap name was wrong (`opencode-ai/tap` vs the real `anomalyco/tap`).

## Root Cause

No audit loop existed to catch drift between declared packages and installed packages. Manual maintenance without periodic diffing allowed the two sources to diverge silently.

## Working Fix

1. Generate canonical installed lists:
   ```bash
   brew leaves --installed-on-request | sort
   brew list --cask | sort
   npm list -g --depth=0
   ```
2. Extract repo-declared lists and diff with `comm`:
   ```bash
   # Brew formulae gap
   comm -23 <(brew leaves --installed-on-request | sort) <(jq -r '.. | objects | .brew[]? | .name' packages.json | sort)
   # Cask gap
   comm -23 <(brew list --cask | sort) <(jq -r '.. | objects | .cask[]? | .name' packages.json | sort)
   # npm gap
   comm -23 <(npm list -g --depth=0 | tail -n +2 | sed 's/.*── //' | sed 's/@[0-9].*//' | sort) <(jq -r '.. | objects | .npm[]?' packages.json | sort)
   ```
3. Add missing entries to `packages.json` under the correct profile key.
4. Fix wrong tap names; skip intentional non-entries (e.g. `stow`, `corepack`, `npm`).
5. Validate and regenerate: `jq empty packages.json && gmake brewfile`.

## Reuse Guidance

- When to apply: Before committing any package changes, or when Brewfile diverges from what is installed. Also run when onboarding to a new machine to surface hidden drift.
- Pitfalls to avoid: Do not edit `Brewfile` directly — it is a generated artifact. Never add Node.js built-ins (`npm`, `corepack`) or legacy tools replaced by Tuckr (`stow`) to `packages.json`.

## Tags

homebrew, packages-json, brewfile, npm, drift, jq, audit, developer-experience
