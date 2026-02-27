#!/usr/bin/env bash
# test_idempotency.sh — Verify that repeated dotfiles deploy is idempotent.
# Requires tuckr to be installed and groups to be deployable.
# Skips with exit code 2 if tuckr is unavailable.

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd tuckr; then
  exit 2
fi
if ! require_cmd gmake; then
  exit 2
fi

ROOT="$(repo_root)"
FAILED=0

# --- Ensure at least one group is deployed before testing idempotency ---
DEPLOYED=0
for group in zsh git vim; do
  out="$(cd "$ROOT" && tuckr status "$group" 2>&1 || true)"
  if echo "$out" | grep -q "Symlinked:"; then
    DEPLOYED=$((DEPLOYED + 1))
  fi
done

if [ "$DEPLOYED" -eq 0 ]; then
  skip "idempotency test: no groups deployed, skipping"
  exit 2
fi

# --- Run tuckr set * a second time — must succeed without errors ---
if cd "$ROOT" && tuckr set '*' >/dev/null 2>&1; then
  pass "second tuckr deploy (idempotency): exits 0"
else
  fail "second tuckr deploy failed — not idempotent" || true
  FAILED=1
fi

# --- Symlink targets must be unchanged after second deploy ---
declare -A EXPECTED_TARGETS
EXPECTED_TARGETS["$HOME/.zshrc"]="$ROOT/Configs/zsh/.zshrc"
EXPECTED_TARGETS["$HOME/.gitconfig"]="$ROOT/Configs/git/.gitconfig"
EXPECTED_TARGETS["$HOME/.vimrc"]="$ROOT/Configs/vim/.vimrc"

for link in "${!EXPECTED_TARGETS[@]}"; do
  expected="${EXPECTED_TARGETS[$link]}"
  if [ ! -L "$link" ]; then
    skip "symlink not present after redeploy: $link"
    continue
  fi
  actual="$(readlink "$link")"
  if [ "$actual" = "$expected" ]; then
    pass "idempotent symlink target ok: $link"
  else
    fail "symlink target changed after redeploy: $link (got: $actual, expected: $expected)" || true
    FAILED=1
  fi
done

# --- dotfiles-verify must pass after second deploy ---
if gmake -C "$ROOT" dotfiles-verify >/dev/null 2>&1; then
  pass "dotfiles-verify passes after second deploy"
else
  fail "dotfiles-verify failed after second deploy" || true
  FAILED=1
fi

exit $FAILED
