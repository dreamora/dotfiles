#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd shellcheck; then
  exit 2
fi

ROOT="$(repo_root)"
FAILED=0

FILES=(
  "$ROOT/bootstrap.sh"
  "$ROOT/lib_sh/echos.sh"
  "$ROOT/lib_sh/requirers.sh"
  "$ROOT/lib_sh/asdf_setup.sh"
  "$ROOT/Hooks/neovim/pre.sh"
)

while IFS= read -r script; do
  FILES+=("$script")
done < <(find "$ROOT/scripts" -maxdepth 1 -type f -name '*.sh' 2>/dev/null || true)

for file in "${FILES[@]}"; do
  if shellcheck -x -S error -e SC1090,SC1091,SC1087 "$file" >/dev/null 2>&1; then
    pass "shellcheck ok: ${file#$ROOT/}"
  else
    fail "shellcheck failed: ${file#$ROOT/}" || true
    shellcheck -x -S error -e SC1090,SC1091,SC1087 "$file" || true
    FAILED=1
  fi
done

exit $FAILED
