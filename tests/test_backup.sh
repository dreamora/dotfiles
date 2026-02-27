#!/usr/bin/env bash
# test_backup.sh — Verify backup and rollback targets work correctly.
# Creates a real backup snapshot and validates its structure/manifest.

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd gmake; then
  exit 2
fi

ROOT="$(repo_root)"
FAILED=0
BACKUP_BASE="$HOME/.dotfiles-backups"

# --- dotfiles-backup: must create a timestamped snapshot directory ---
BEFORE_COUNT=$(ls -1 "$BACKUP_BASE" 2>/dev/null | wc -l | xargs || echo 0)

if gmake -C "$ROOT" dotfiles-backup >/dev/null 2>&1; then
  pass "dotfiles-backup exits 0"
else
  fail "dotfiles-backup failed" || true
  FAILED=1
fi

AFTER_COUNT=$(ls -1 "$BACKUP_BASE" 2>/dev/null | wc -l | xargs)
if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
  pass "dotfiles-backup created new snapshot directory"
else
  fail "dotfiles-backup did not create a new snapshot directory" || true
  FAILED=1
fi

# --- snapshot must contain manifest.json ---
LATEST="$(ls -1td "$BACKUP_BASE"/[0-9]* 2>/dev/null | head -1)"
if [ -z "$LATEST" ]; then
  fail "no snapshot found after backup" || true
  FAILED=1
else
  if [ -f "$LATEST/manifest.json" ]; then
    pass "snapshot contains manifest.json"
  else
    fail "snapshot missing manifest.json at $LATEST" || true
    FAILED=1
  fi

  # --- manifest.json must have expected keys ---
  if command -v jq >/dev/null 2>&1; then
    for key in timestamp snapshot dotfiles_dir; do
      if jq -e ".$key" "$LATEST/manifest.json" >/dev/null 2>&1; then
        pass "manifest.json has key: $key"
      else
        fail "manifest.json missing key: $key" || true
        FAILED=1
      fi
    done
  else
    skip "jq not available — skipping manifest key validation"
  fi

  # --- snapshot must contain home/ subdirectory ---
  if [ -d "$LATEST/home" ]; then
    pass "snapshot contains home/ subdirectory"
  else
    fail "snapshot missing home/ subdirectory" || true
    FAILED=1
  fi
fi

# --- backup-list: must exit 0 and list snapshots ---
LIST_OUTPUT=$(gmake -C "$ROOT" backup-list 2>&1)
if echo "$LIST_OUTPUT" | grep -q "dotfiles-backups\|no snapshots"; then
  pass "backup-list exits 0 and prints output"
else
  fail "backup-list did not produce expected output" || true
  FAILED=1
fi

# --- gmake -n dotfiles-rollback: dry-run syntax must be valid ---
if gmake -C "$ROOT" -n dotfiles-rollback >/dev/null 2>&1; then
  pass "gmake -n dotfiles-rollback: dry-run syntax ok"
else
  fail "gmake -n dotfiles-rollback failed" || true
  FAILED=1
fi

exit $FAILED
