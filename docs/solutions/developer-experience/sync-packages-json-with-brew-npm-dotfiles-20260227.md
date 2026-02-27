---
module: Dotfiles
date: 2026-02-27
problem_type: developer_experience
component: tooling
symptoms:
  - "Diffing brew leaves, casks, and npm globals against packages.json showed missing entries (brew, cask, npm)."
  - "Homebrew tap list in packages.json didn't match installed taps (opencode-ai/tap vs anomalyco/tap)."
root_cause: missing_tooling
resolution_type: workflow_improvement
severity: medium
tags: [homebrew, packages-json, brewfile, npm, drift, jq, audit]
---

# Troubleshooting: Sync packages.json with installed Homebrew and npm globals

## Problem
`packages.json` is the single source of truth for package installs, but it drifted from what was actually installed via Homebrew and npm.

## Environment
- Module: Dotfiles
- Affected Component: tooling
- Date: 2026-02-27

## Symptoms
- `brew leaves --installed-on-request`, `brew list --cask`, and `npm list -g --depth=0` contained many packages not represented in `packages.json`.
- A tap name in `packages.json` was wrong (`opencode-ai/tap` listed, but `anomalyco/tap` installed).

## What Didn't Work
**Direct solution:** The drift was identified and fixed on the first attempt.

## Solution
1. Generate canonical installed lists:

```bash
brew leaves --installed-on-request | sort
brew list --cask | sort
npm list -g --depth=0
```

2. Extract current `packages.json` entries (example for brew):

```bash
jq -r '.. | objects | .brew[]? | .name' packages.json | sort
```

3. Diff to find gaps (example for brew):

```bash
comm -23 <(brew leaves --installed-on-request | sort) <(jq -r '.. | objects | .brew[]? | .name' packages.json | sort)
```

4. Add missing entries to the right sections in `packages.json`:
- `common.brew` for formulae
- `common.cask` for casks
- `common.npm` for global npm packages

5. Fix wrong tap name:
- `opencode-ai/tap` -> `anomalyco/tap`

6. Skip intentional non-entries:
- `stow` (replaced by Tuckr)
- `corepack` and `npm` (Node.js built-ins)
- `docker` cask (alias for `docker-desktop` already tracked)

7. Validate and regenerate:

```bash
jq empty packages.json
gmake brewfile
```

## Why This Works
The drift came from manual maintenance without any audit loop.

Generating canonical lists from the system, extracting the repo's declared lists, and using `comm` to diff makes the gap explicit and repeatable. Updating `packages.json` and regenerating the derived `Brewfile` restores the intended "single source of truth" flow.

## Prevention
Run these audits periodically, or before committing package changes.

```bash
# Brew formulae gap
comm -23 <(brew leaves --installed-on-request | sort) <(jq -r '.. | objects | .brew[]? | .name' packages.json | sort)

# Cask gap
comm -23 <(brew list --cask | sort) <(jq -r '.. | objects | .cask[]? | .name' packages.json | sort)

# npm gap
comm -23 <(npm list -g --depth=0 | tail -n +2 | sed 's/.*── //' | sed 's/@[0-9].*//' | sort) <(jq -r '.. | objects | .npm[]?' packages.json | sort)
```

## Related Issues
No related issues documented yet.
