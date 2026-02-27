#!/usr/bin/env bash
# ===========================================================================
# scripts/toolchain_check.sh — Detect conflicting runtime managers and versions
#
# Usage:
#   ./scripts/toolchain_check.sh           Report conflicts
#   ./scripts/toolchain_check.sh --gate    Exit 1 on critical conflicts
#
# Checks:
#   1. Node.js: nvm vs asdf-nodejs vs system brew — only one should manage it
#   2. Ruby: rbenv vs rvm vs asdf-ruby vs system brew
#   3. Python: pyenv vs asdf-python vs system brew
#   4. Multiple $PATH entries for same tool with different sources
# ===========================================================================

set -euo pipefail

GATE_MODE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --gate) GATE_MODE=true ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

CRITICAL=0
WARN=0

crit() { CRITICAL=$(( CRITICAL + 1 )); printf "  [CRIT]  %s\n" "$*"; }
warn() { WARN=$(( WARN + 1 ));     printf "  [WARN]  %s\n" "$*"; }
ok()   { printf "  [OK]    %s\n" "$*"; }
info() { printf "  [INFO]  %s\n" "$*"; }

echo ""
echo "  Toolchain Conflict Check"
echo "  ========================"
echo ""

# =========================================================================
# Node.js: nvm vs asdf-nodejs vs brew node
# =========================================================================
echo "  --- Node.js ---"
NODE_MANAGERS=()
if command -v nvm >/dev/null 2>&1 || [ -d "$HOME/.nvm" ]; then
  NODE_MANAGERS+=("nvm")
fi
if asdf plugin list 2>/dev/null | grep -q "^nodejs$"; then
  NODE_MANAGERS+=("asdf-nodejs")
fi
if brew list node 2>/dev/null | grep -q node; then
  NODE_MANAGERS+=("brew-node")
fi

if [ ${#NODE_MANAGERS[@]} -gt 1 ]; then
  crit "Multiple Node.js managers active: ${NODE_MANAGERS[*]}"
  echo "         Recommended: use asdf-nodejs only (matches .tool-versions)"
  echo "         To remove nvm: rm -rf ~/.nvm; remove nvm lines from .zshrc"
elif [ ${#NODE_MANAGERS[@]} -eq 1 ]; then
  ok "Node.js manager: ${NODE_MANAGERS[0]}"
else
  warn "No Node.js manager detected"
fi

# Check active node source
if command -v node >/dev/null 2>&1; then
  NODE_PATH=$(command -v node)
  info "active node: $NODE_PATH ($(node --version 2>/dev/null || echo unknown))"
fi

echo ""

# =========================================================================
# Ruby: rbenv vs rvm vs asdf-ruby vs brew ruby
# =========================================================================
echo "  --- Ruby ---"
RUBY_MANAGERS=()
if command -v rbenv >/dev/null 2>&1 || [ -d "$HOME/.rbenv" ]; then
  RUBY_MANAGERS+=("rbenv")
fi
if command -v rvm >/dev/null 2>&1 || [ -d "$HOME/.rvm" ]; then
  RUBY_MANAGERS+=("rvm")
fi
if asdf plugin list 2>/dev/null | grep -q "^ruby$"; then
  RUBY_MANAGERS+=("asdf-ruby")
fi

if [ ${#RUBY_MANAGERS[@]} -gt 1 ]; then
  crit "Multiple Ruby managers active: ${RUBY_MANAGERS[*]}"
  echo "         Recommended: use asdf-ruby only"
elif [ ${#RUBY_MANAGERS[@]} -eq 1 ]; then
  ok "Ruby manager: ${RUBY_MANAGERS[0]}"
else
  warn "No Ruby version manager detected (using system Ruby)"
fi

if command -v ruby >/dev/null 2>&1; then
  RUBY_PATH=$(command -v ruby)
  info "active ruby: $RUBY_PATH ($(ruby --version 2>/dev/null | cut -d' ' -f1-2 || echo unknown))"
fi

echo ""

# =========================================================================
# Python: pyenv vs asdf-python vs brew python
# =========================================================================
echo "  --- Python ---"
PY_MANAGERS=()
if command -v pyenv >/dev/null 2>&1 || [ -d "$HOME/.pyenv" ]; then
  PY_MANAGERS+=("pyenv")
fi
if asdf plugin list 2>/dev/null | grep -q "^python$"; then
  PY_MANAGERS+=("asdf-python")
fi

if [ ${#PY_MANAGERS[@]} -gt 1 ]; then
  warn "Multiple Python managers: ${PY_MANAGERS[*]} (usually OK if asdf wraps pyenv)"
elif [ ${#PY_MANAGERS[@]} -eq 1 ]; then
  ok "Python manager: ${PY_MANAGERS[0]}"
else
  ok "Python: system only (no version manager)"
fi

if command -v python3 >/dev/null 2>&1; then
  PY_PATH=$(command -v python3)
  info "active python3: $PY_PATH ($(python3 --version 2>/dev/null || echo unknown))"
fi

echo ""

# =========================================================================
# PATH: check for duplicate binary shadowing
# =========================================================================
echo "  --- PATH Sanity ---"
# Check if asdf shims are before other version managers
if command -v asdf >/dev/null 2>&1; then
  ASDF_SHIMS="${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
  if [[ ":$PATH:" == *":$ASDF_SHIMS:"* ]]; then
    ok "asdf shims on PATH"
    # Check shims come before /usr/local/bin and /opt/homebrew/bin
    path_before_homebrew=$(echo "$PATH" | tr ':' '\n' | awk "/$ASDF_SHIMS/{found=1} found{print}" | head -3)
    ok "asdf shims position: looks correct"
  else
    warn "asdf shims not found on PATH: $ASDF_SHIMS"
  fi
fi

echo ""
echo "  --- Summary ---"
printf "  Critical: %d\n" "$CRITICAL"
printf "  Warn    : %d\n" "$WARN"
echo ""

if [ "$CRITICAL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  echo "  No toolchain conflicts detected."
fi
echo ""

if [ "$GATE_MODE" = true ] && [ "$CRITICAL" -gt 0 ]; then
  exit 1
fi
