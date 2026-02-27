#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

ROOT="$(repo_root)"
FAILED=0

if [[ ! -f "$ROOT/.gitmodules" ]]; then
  skip ".gitmodules not present"
  exit 2
fi

while IFS= read -r path; do
  if [[ -z "$path" ]]; then
    continue
  fi

  if [[ ! -d "$ROOT/$path" ]]; then
    fail "submodule path missing: $path" || true
    FAILED=1
    continue
  fi

  if [[ -z "$(ls -A "$ROOT/$path" 2>/dev/null || true)" ]]; then
    fail "submodule path is empty (not initialized?): $path" || true
    FAILED=1
  else
    pass "submodule path initialized: $path"
  fi
done < <(git -C "$ROOT" config --file .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')

exit $FAILED
