#!/usr/bin/env bash

set -u

pass() {
  printf 'PASS: %s\n' "$*"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  return 1
}

skip() {
  printf 'SKIP: %s\n' "$*"
  return 2
}

info() {
  printf 'INFO: %s\n' "$*"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    skip "missing required command: $cmd"
    return 2
  fi
  return 0
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}
