#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

ROOT="$(repo_root)"
FAILED=0

GROUP_NAMES=(zsh git vim neovim tmux screen ruby node asdf crontab)

for group in "${GROUP_NAMES[@]}"; do
  if [[ -d "$ROOT/configs/$group" ]]; then
    pass "group exists: configs/$group"
  else
    fail "missing group directory: configs/$group" || true
    FAILED=1
  fi
done

for file in \
  "$ROOT/Makefile" \
  "$ROOT/bootstrap.sh" \
  "$ROOT/make/bootstrap.mk" \
  "$ROOT/make/tuckr.mk" \
  "$ROOT/make/tools.mk" \
  "$ROOT/make/packages.mk" \
  "$ROOT/make/system.mk" \
  "$ROOT/make/macos.mk" \
  "$ROOT/make/test.mk"; do
  if [[ -f "$file" ]]; then
    pass "required file exists: ${file#$ROOT/}"
  else
    fail "missing required file: ${file#$ROOT/}" || true
    FAILED=1
  fi
done

if [[ -x "$ROOT/Hooks/neovim/pre.sh" ]]; then
  pass "neovim pre-hook is executable"
else
  fail "Hooks/neovim/pre.sh is missing or not executable" || true
  FAILED=1
fi

exit $FAILED
