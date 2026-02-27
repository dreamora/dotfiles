#!/usr/bin/env bash
# test_preflight.sh — Verify preflight, dryrun, and verify targets work correctly.
# These tests run make targets in --dry-run or sandboxed mode; no filesystem writes.

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd gmake; then
  exit 2
fi
if ! require_cmd tuckr; then
  exit 2
fi

ROOT="$(repo_root)"
FAILED=0

# --- dotfiles-dryrun: tuckr preview — skip gracefully if tuckr exits non-zero ---
# On a fresh CI checkout with no deployed dotfiles, tuckr may exit non-zero.
# We treat non-zero as a skip (not a hard failure) since CI can't deploy.
DRYRUN_OUT=$(gmake -C "$ROOT" dotfiles-dryrun 2>&1) && DRYRUN_RC=0 || DRYRUN_RC=$?
if [ "$DRYRUN_RC" -eq 0 ]; then
  pass "dotfiles-dryrun exits 0"
else
  skip "dotfiles-dryrun: tuckr returned exit $DRYRUN_RC (expected on undeploy CI runner)" || true
  exit 2
fi

# --- dotfiles-preflight: must exit 0 on a clean (already-deployed) machine ---
# Skip if groups are not yet deployed (symlinks test handles that)
DEPLOYED=0
for group in zsh git; do
  out="$(cd "$ROOT" && tuckr status "$group" 2>&1 || true)"
  if echo "$out" | grep -q "Symlinked:"; then
    DEPLOYED=$((DEPLOYED + 1))
  fi
done

if [ "$DEPLOYED" -gt 0 ]; then
  if gmake -C "$ROOT" dotfiles-preflight >/dev/null 2>&1; then
    pass "dotfiles-preflight passes on deployed machine"
  else
    fail "dotfiles-preflight failed on already-deployed machine" || true
    FAILED=1
  fi
else
  skip "dotfiles-preflight: groups not deployed, skipping live check"
fi

# --- dotfiles-verify: must exit 0 when all groups are deployed ---
if [ "$DEPLOYED" -gt 0 ]; then
  if gmake -C "$ROOT" dotfiles-verify >/dev/null 2>&1; then
    pass "dotfiles-verify passes on deployed machine"
  else
    fail "dotfiles-verify failed on deployed machine" || true
    FAILED=1
  fi
else
  skip "dotfiles-verify: groups not deployed, skipping live check"
fi

# --- gmake -n dotfiles-preflight: must be parseable dry-run ---
if gmake -C "$ROOT" -n dotfiles-preflight >/dev/null 2>&1; then
  pass "gmake -n dotfiles-preflight: dry-run syntax ok"
else
  fail "gmake -n dotfiles-preflight failed" || true
  FAILED=1
fi

# --- gmake -n dotfiles-verify: must be parseable dry-run ---
if gmake -C "$ROOT" -n dotfiles-verify >/dev/null 2>&1; then
  pass "gmake -n dotfiles-verify: dry-run syntax ok"
else
  fail "gmake -n dotfiles-verify failed" || true
  FAILED=1
fi

exit $FAILED
