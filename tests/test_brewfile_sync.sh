#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd gmake; then
  exit 2
fi
if ! require_cmd jq; then
  exit 2
fi

ROOT="$(repo_root)"
ORIGINAL="$(mktemp)"
cp "$ROOT/Brewfile" "$ORIGINAL"

cleanup() {
  cp "$ORIGINAL" "$ROOT/Brewfile"
  rm -f "$ORIGINAL"
}
trap cleanup EXIT

if ! gmake -C "$ROOT" brewfile >/dev/null 2>&1; then
  fail "failed to regenerate Brewfile"
  exit 1
fi

if diff -q "$ROOT/Brewfile" "$ORIGINAL" >/dev/null 2>&1; then
  pass "Brewfile is in sync with packages.json"
  exit 0
fi

fail "Brewfile drift detected (run: gmake brewfile and commit)"
exit 1
