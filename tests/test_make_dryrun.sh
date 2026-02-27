#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd gmake; then
  exit 2
fi

ROOT="$(repo_root)"
FAILED=0

TARGETS=(
  help
  clean
  brewfile
  dotfiles
  dotfiles-rm
  dotfiles-preflight
  dotfiles-dryrun
  dotfiles-verify
  dotfiles-backup
  dotfiles-rollback
  backup-list
  tuckr-status
  packages-common
  packages-private
  packages-entertainment
  packages-work
  packages-work-optional
  tools
  tool-zsh
  tool-git
  tool-vim
  tool-node
  tool-asdf
  tool-fonts
  shell-bench
  shell-bench-profile
  shell-bench-ci
  drift
  drift-gate
  drift-json
  secrets-status
  secrets-check-key
  role
  role-apply
  role-set
  role-check
  audit-log
  audit-summary
  toolchain-check
  toolchain-check-gate
  test-quick
)

for target in "${TARGETS[@]}"; do
  if gmake -C "$ROOT" -n "$target" >/dev/null 2>&1; then
    pass "gmake -n $target"
  else
    fail "gmake -n failed for target: $target" || true
    FAILED=1
  fi
done

exit $FAILED
