#!/usr/bin/env bash
# ===========================================================================
# scripts/drift_check.sh — Declared-vs-actual drift detection
#
# Usage:
#   ./scripts/drift_check.sh              Run drift check (report only)
#   ./scripts/drift_check.sh --gate       Gate mode: exit 1 on critical drift
#   ./scripts/drift_check.sh --json       Output as JSON (for tooling)
#
# Checks:
#   1. Dotfiles: tuckr status vs expected groups
#   2. Homebrew formulae: installed vs packages.json declared
#   3. Homebrew casks: installed vs packages.json declared
#   4. npm globals: installed vs packages.json declared
# ===========================================================================

set -euo pipefail

GATE_MODE=false
JSON_MODE=false
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gate) GATE_MODE=true ;;
    --json) JSON_MODE=true ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

# --- Helpers ---
CRITICAL_DRIFT=0
WARN_DRIFT=0

warn_drift() { WARN_DRIFT=$(( WARN_DRIFT + 1 )); printf "  [WARN]  %s\n" "$*"; }
crit_drift() { CRITICAL_DRIFT=$(( CRITICAL_DRIFT + 1 )); printf "  [CRIT]  %s\n" "$*"; }
ok_status()  { printf "  [OK]    %s\n" "$*"; }

TUCKR_GROUPS=(zsh git vim neovim tmux screen ruby node asdf crontab)

if [ "$JSON_MODE" = false ]; then
  echo ""
  echo "  Dotfiles Drift Check"
  echo "  ===================="
  echo ""
fi

# =========================================================================
# 1. Dotfiles: tuckr symlink state
# =========================================================================
declare -A SYMLINK_STATE

if command -v tuckr >/dev/null 2>&1; then
  SYMLINK_NOT_DEPLOYED=()
  for group in "${TUCKR_GROUPS[@]}"; do
    out="$(cd "$ROOT_DIR" && tuckr status "$group" 2>&1 || true)"
    if echo "$out" | grep -q "Symlinked:"; then
      SYMLINK_STATE["$group"]="ok"
      if [ "$JSON_MODE" = false ]; then ok_status "dotfiles/$group: symlinked"; fi
    else
      SYMLINK_STATE["$group"]="missing"
      SYMLINK_NOT_DEPLOYED+=("$group")
      crit_drift "dotfiles/$group: NOT symlinked — run: gmake $group"
    fi
  done
else
  warn_drift "tuckr not installed — cannot check dotfile symlink state"
fi

# =========================================================================
# 2. Homebrew formulae drift
# =========================================================================
BREW_DRIFT=()
if command -v brew >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  if [ "$JSON_MODE" = false ]; then echo ""; fi

  # Declared in packages.json
  DECLARED_BREW=$(jq -r '.. | objects | .brew[]? | if type == "object" then .name else . end' "$ROOT_DIR/packages.json" | sort -u)
  # Installed
  INSTALLED_BREW=$(brew leaves --installed-on-request 2>/dev/null | sort || true)

  # In installed but NOT declared
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    # Skip known intentional non-entries
    case "$pkg" in
      stow|corepack|npm|make) continue ;;
    esac
    if ! echo "$DECLARED_BREW" | grep -qx "$pkg"; then
      BREW_DRIFT+=("$pkg")
      warn_drift "brew/$pkg: installed but not declared in packages.json"
    fi
  done <<< "$INSTALLED_BREW"

  if [ ${#BREW_DRIFT[@]} -eq 0 ]; then
    ok_status "brew formulae: no undeclared packages"
  fi
else
  warn_drift "brew or jq not installed — skipping formulae drift check"
fi

# =========================================================================
# 3. Homebrew casks drift
# =========================================================================
CASK_DRIFT=()
if command -v brew >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  DECLARED_CASK=$(jq -r '.. | objects | .cask[]? | if type == "object" then .name else . end' "$ROOT_DIR/packages.json" | sort -u)
  INSTALLED_CASK=$(brew list --cask 2>/dev/null | sort || true)

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    case "$pkg" in
      docker) continue ;; # alias for docker-desktop
    esac
    if ! echo "$DECLARED_CASK" | grep -qx "$pkg"; then
      CASK_DRIFT+=("$pkg")
      warn_drift "cask/$pkg: installed but not declared in packages.json"
    fi
  done <<< "$INSTALLED_CASK"

  if [ ${#CASK_DRIFT[@]} -eq 0 ]; then
    ok_status "brew casks: no undeclared packages"
  fi
fi

# =========================================================================
# 4. npm global packages drift
# =========================================================================
NPM_DRIFT=()
if command -v npm >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  DECLARED_NPM=$(jq -r '.. | objects | .npm[]?' "$ROOT_DIR/packages.json" 2>/dev/null | sort -u)
  INSTALLED_NPM=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | sed 's/.*── //' | sed 's/@[0-9].*//' | sort || true)

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    case "$pkg" in
      corepack|npm) continue ;;
    esac
    if ! echo "$DECLARED_NPM" | grep -qx "$pkg"; then
      NPM_DRIFT+=("$pkg")
      warn_drift "npm/$pkg: installed globally but not declared in packages.json"
    fi
  done <<< "$INSTALLED_NPM"

  if [ ${#NPM_DRIFT[@]} -eq 0 ]; then
    ok_status "npm globals: no undeclared packages"
  fi
fi

# =========================================================================
# Summary
# =========================================================================
if [ "$JSON_MODE" = true ]; then
  printf '{"critical":%d,"warn":%d}\n' "$CRITICAL_DRIFT" "$WARN_DRIFT"
else
  echo ""
  echo "  --- Drift Summary ---"
  printf "  Critical: %d\n" "$CRITICAL_DRIFT"
  printf "  Warn    : %d\n" "$WARN_DRIFT"
  echo ""

  if [ "$CRITICAL_DRIFT" -eq 0 ] && [ "$WARN_DRIFT" -eq 0 ]; then
    echo "  No drift detected."
  elif [ "$CRITICAL_DRIFT" -gt 0 ]; then
    echo "  Critical drift found. Run 'gmake dotfiles' to fix symlinks."
  fi
  echo ""
fi

if [ "$GATE_MODE" = true ] && [ "$CRITICAL_DRIFT" -gt 0 ]; then
  exit 1
fi
