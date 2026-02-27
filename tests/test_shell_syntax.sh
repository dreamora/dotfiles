#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

ROOT="$(repo_root)"
FAILED=0

if ! require_cmd zsh; then
  exit 2
fi

ZSH_FILES=(
  "$ROOT/configs/zsh/.zshrc"
  "$ROOT/configs/zsh/.zprofile"
  "$ROOT/configs/zsh/.zshenv"
  "$ROOT/configs/zsh/.zlogout"
)

for file in "${ZSH_FILES[@]}"; do
  if zsh -n "$file" >/dev/null 2>&1; then
    pass "zsh syntax ok: ${file#$ROOT/}"
  else
    fail "zsh syntax failed: ${file#$ROOT/}" || true
    FAILED=1
  fi
done

BASH_FILES=(
  "$ROOT/bootstrap.sh"
  "$ROOT/lib_sh/echos.sh"
  "$ROOT/lib_sh/requirers.sh"
  "$ROOT/lib_sh/asdf_setup.sh"
  "$ROOT/Hooks/neovim/pre.sh"
)

for file in "${BASH_FILES[@]}"; do
  if bash -n "$file" >/dev/null 2>&1; then
    pass "bash syntax ok: ${file#$ROOT/}"
  else
    fail "bash syntax failed: ${file#$ROOT/}" || true
    FAILED=1
  fi
done

exit $FAILED
