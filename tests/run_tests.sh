#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$ROOT_DIR/tests"

MODE="quick"
if [[ "${1:-}" == "--full" ]]; then
  MODE="full"
elif [[ "${1:-}" == "--lint" ]]; then
  MODE="lint"
elif [[ "${1:-}" == "--quick" || -z "${1:-}" ]]; then
  MODE="quick"
fi

run_test() {
  local script="$1"
  printf '\n=== %s ===\n' "$(basename "$script")"
  if bash "$script"; then
    PASSED=$((PASSED + 1))
    return 0
  fi

  local rc
  rc=$?
  if [[ $rc -eq 2 ]]; then
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  FAILED=$((FAILED + 1))
  return 0
}

PASSED=0
FAILED=0
SKIPPED=0

BASE_TESTS=(
  "$TEST_DIR/test_repo_structure.sh"
  "$TEST_DIR/test_packages_json.sh"
  "$TEST_DIR/test_case_consistency.sh"
  "$TEST_DIR/test_submodules.sh"
  "$TEST_DIR/test_make_dryrun.sh"
  "$TEST_DIR/test_brewfile_sync.sh"
)

LINT_TESTS=(
  "$TEST_DIR/test_shell_syntax.sh"
  "$TEST_DIR/test_shellcheck.sh"
)

FULL_ONLY_TESTS=(
  "$TEST_DIR/test_symlinks.sh"
  "$TEST_DIR/test_idempotency.sh"
  "$TEST_DIR/test_conflict_detection.sh"
)

# INTEGRATION_TESTS run in quick+full (skip gracefully when tuckr not deployed)
INTEGRATION_TESTS=(
  "$TEST_DIR/test_preflight.sh"
  "$TEST_DIR/test_backup.sh"
)

if [[ "$MODE" == "lint" ]]; then
  TESTS=("${LINT_TESTS[@]}")
elif [[ "$MODE" == "full" ]]; then
  TESTS=("${BASE_TESTS[@]}" "${LINT_TESTS[@]}" "${INTEGRATION_TESTS[@]}" "${FULL_ONLY_TESTS[@]}")
else
  TESTS=("${BASE_TESTS[@]}" "${LINT_TESTS[@]}" "${INTEGRATION_TESTS[@]}")
fi

printf 'Running mode: %s\n' "$MODE"
for test_script in "${TESTS[@]}"; do
  run_test "$test_script"
done

printf '\n--- Test Summary ---\n'
printf 'Passed : %d\n' "$PASSED"
printf 'Failed : %d\n' "$FAILED"
printf 'Skipped: %d\n' "$SKIPPED"

if [[ $FAILED -ne 0 ]]; then
  exit 1
fi
