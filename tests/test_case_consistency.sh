#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

ROOT="$(repo_root)"
FAILED=0

CONFIG_DIR_NAME="$(find "$ROOT" -maxdepth 1 -mindepth 1 -type d -name '[Cc]onfigs' -exec basename {} \; | head -1)"

if [[ "$CONFIG_DIR_NAME" == "configs" ]]; then
  pass "using lowercase configs/ directory"
elif [[ "$CONFIG_DIR_NAME" == "Configs" ]]; then
  pass "using uppercase Configs/ directory"
else
  fail "could not determine config root directory name" || true
  FAILED=1
fi

CODE_PATHS=("$ROOT/Makefile" "$ROOT/make" "$ROOT/bootstrap.sh" "$ROOT/lib_sh" "$ROOT/Hooks")

LOWER_REFS="$(grep -R --line-number 'configs/' "${CODE_PATHS[@]}" 2>/dev/null || true)"
UPPER_REFS="$(grep -R --line-number 'Configs/' "${CODE_PATHS[@]}" 2>/dev/null || true)"

if [[ "$CONFIG_DIR_NAME" == "configs" && -n "$UPPER_REFS" ]]; then
  fail "code references Configs/ but repository directory is configs/: $UPPER_REFS" || true
  FAILED=1
else
  pass "code references align with repository config directory casing"
fi

if [[ "$CONFIG_DIR_NAME" == "Configs" && -n "$LOWER_REFS" ]]; then
  fail "code references configs/ but repository directory is Configs/: $LOWER_REFS" || true
  FAILED=1
fi

exit $FAILED
