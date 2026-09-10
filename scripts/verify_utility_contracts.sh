#!/usr/bin/env bash

set -euo pipefail

umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT_UNDER_TEST="$ROOT_DIR/scripts/convert-android-keystore.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/verify-utility-contracts.XXXXXX")"

passed=0
failed=0

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
  printf 'PASS: %s\n' "$1"
  passed=$((passed + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failed=$((failed + 1))
}

assert_failure_before_keytool() {
  local description="$1"
  local status="$2"
  local log_file="$3"

  if [[ $status -ne 0 && ! -s $log_file ]]; then
    pass "$description"
  else
    fail "$description"
  fi
}

wait_for_file() {
  local file="$1"
  local attempt

  attempt=0
  while [[ $attempt -lt 100 ]]; do
    [[ -e $file ]] && return 0
    sleep 0.02
    attempt=$((attempt + 1))
  done
  return 1
}

stub_dir="$TEST_ROOT/stub bin"
mkdir -p "$stub_dir"
cat > "$stub_dir/keytool" <<'STUB'
#!/usr/bin/env bash

set -euo pipefail

call=1
if [[ -f $KEYTOOL_STATE ]]; then
  IFS= read -r call < "$KEYTOOL_STATE"
  call=$((call + 1))
fi
printf '%s\n' "$call" > "$KEYTOOL_STATE"

printf 'CALL:%s\n' "$call" >> "$KEYTOOL_LOG"
for argument in "$@"; do
  printf 'ARG:%s\n' "$argument" >> "$KEYTOOL_LOG"
done

if [[ ${KEYSTORE_PASS+x} && $KEYSTORE_PASS == "$STUB_EXPECTED_PASS" ]]; then
  printf 'ENV:ok\n' >> "$KEYTOOL_LOG"
else
  printf 'ENV:bad\n' >> "$KEYTOOL_LOG"
fi

if [[ $call -eq 1 && -n ${KEYTOOL_STARTED_FILE:-} ]]; then
  : > "$KEYTOOL_STARTED_FILE"
  while [[ ! -e $KEYTOOL_RELEASE_FILE ]]; do
    sleep 0.02
  done
fi

destination=""
previous=""
for argument in "$@"; do
  if [[ $previous == -file || $previous == -destkeystore ]]; then
    destination="$argument"
  fi
  previous="$argument"
done

if [[ -n $destination ]]; then
  : > "$destination"
fi

if [[ ${KEYTOOL_FAIL_CALL:-0} -eq $call ]]; then
  exit 42
fi
STUB
chmod +x "$stub_dir/keytool"

sentinel='utility-contract-secret-9f31'

missing_args_dir="$TEST_ROOT/missing args"
mkdir -p "$missing_args_dir"
missing_args_log="$missing_args_dir/keytool.log"
set +e
(
  cd "$missing_args_dir"
  PATH="$stub_dir:$PATH" \
    KEYTOOL_LOG="$missing_args_log" \
    KEYTOOL_STATE="$missing_args_dir/keytool.state" \
    STUB_EXPECTED_PASS="$sentinel" \
    "$SCRIPT_UNDER_TEST"
) > "$missing_args_dir/stdout" 2> "$missing_args_dir/stderr"
missing_args_status=$?
set -e
assert_failure_before_keytool "missing arguments are rejected before keytool" "$missing_args_status" "$missing_args_log"

missing_input_dir="$TEST_ROOT/missing input"
mkdir -p "$missing_input_dir"
missing_input_log="$missing_input_dir/keytool.log"
set +e
(
  cd "$missing_input_dir"
  PATH="$stub_dir:$PATH" \
    KEYSTORE_PASS="$sentinel" \
    KEYTOOL_LOG="$missing_input_log" \
    KEYTOOL_STATE="$missing_input_dir/keytool.state" \
    STUB_EXPECTED_PASS="$sentinel" \
    "$SCRIPT_UNDER_TEST" "release alias" "$missing_input_dir/not present.jks" "$missing_input_dir/output.jks"
) > "$missing_input_dir/stdout" 2> "$missing_input_dir/stderr"
missing_input_status=$?
set -e
assert_failure_before_keytool "missing input is rejected before keytool" "$missing_input_status" "$missing_input_log"

missing_password_dir="$TEST_ROOT/missing password"
mkdir -p "$missing_password_dir"
: > "$missing_password_dir/input.jks"
missing_password_log="$missing_password_dir/keytool.log"
set +e
(
  cd "$missing_password_dir"
  env -u KEYSTORE_PASS \
    PATH="$stub_dir:$PATH" \
    KEYTOOL_LOG="$missing_password_log" \
    KEYTOOL_STATE="$missing_password_dir/keytool.state" \
    STUB_EXPECTED_PASS="$sentinel" \
    "$SCRIPT_UNDER_TEST" "release alias" "$missing_password_dir/input.jks" "$missing_password_dir/output.jks" < /dev/null
) > "$missing_password_dir/stdout" 2> "$missing_password_dir/stderr"
missing_password_status=$?
set -e
if [[ $missing_password_status -ne 0 \
  && ! -s $missing_password_log \
  && $(< "$missing_password_dir/stderr") == *KEYSTORE_PASS* ]]; then
  pass "noninteractive missing password fails clearly before keytool"
else
  fail "noninteractive missing password fails clearly before keytool"
fi

success_dir="$TEST_ROOT/success case"
success_run_dir="$success_dir/run directory"
success_temp_root="$success_dir/temp root"
mkdir -p "$success_run_dir" "$success_temp_root"
success_input="$success_run_dir/input keystore.jks"
success_output="$success_run_dir/output keystore.jks"
success_log="$success_dir/keytool.log"
success_started="$success_dir/keytool.started"
success_release="$success_dir/keytool.release"
: > "$success_input"

set +e
(
  cd "$success_run_dir"
  PATH="$stub_dir:$PATH" \
    TMPDIR="$success_temp_root" \
    KEYSTORE_PASS="$sentinel" \
    KEYTOOL_LOG="$success_log" \
    KEYTOOL_STATE="$success_dir/keytool.state" \
    KEYTOOL_STARTED_FILE="$success_started" \
    KEYTOOL_RELEASE_FILE="$success_release" \
    STUB_EXPECTED_PASS="$sentinel" \
    "$SCRIPT_UNDER_TEST" "release alias" "$success_input" "$success_output"
) > "$success_dir/stdout" 2> "$success_dir/stderr" &
success_pid=$!
set -e

if wait_for_file "$success_started"; then
  process_command="$(ps -o command= -p "$success_pid" 2>/dev/null || true)"
  if [[ $process_command != *"$sentinel"* ]]; then
    pass "wrapper process arguments exclude the password"
  else
    fail "wrapper process arguments exclude the password"
  fi
else
  fail "wrapper reaches keytool for a valid invocation"
fi
: > "$success_release"
set +e
wait "$success_pid"
success_status=$?
set -e

if [[ $success_status -eq 0 && -f $success_output ]]; then
  pass "valid paths containing spaces are supported"
else
  fail "valid paths containing spaces are supported"
fi

if [[ -s $success_log ]] \
  && [[ $(grep -c '^CALL:' "$success_log" || true) -eq 4 ]] \
  && [[ $(grep -c '^ENV:ok$' "$success_log" || true) -eq 4 ]] \
  && ! grep -q '^ENV:bad$' "$success_log" \
  && [[ $(grep -c '^ARG:-storepass:env$' "$success_log" || true) -eq 2 ]] \
  && [[ $(grep -c '^ARG:-srcstorepass:env$' "$success_log" || true) -eq 2 ]] \
  && [[ $(grep -c '^ARG:-deststorepass:env$' "$success_log" || true) -eq 2 ]] \
  && [[ $(grep -c '^ARG:KEYSTORE_PASS$' "$success_log" || true) -eq 6 ]] \
  && ! grep -q '^ARG:-\(storepass\|srcstorepass\|deststorepass\)$' "$success_log" \
  && ! grep -Fq "$sentinel" "$success_log"; then
  pass "keytool receives the password only through environment options"
else
  fail "keytool receives the password only through environment options"
fi

shopt -s nullglob
surviving_files=("$success_run_dir"/*)
shopt -u nullglob
if [[ ${#surviving_files[@]} -eq 2 \
  && ${surviving_files[0]} == "$success_input" \
  && ${surviving_files[1]} == "$success_output" ]]; then
  pass "only the input and requested output survive"
else
  fail "only the input and requested output survive"
fi

if [[ -s $success_log ]] \
  && grep -Fq "ARG:$success_temp_root/" "$success_log" \
  && [[ -z $(find "$success_temp_root" -mindepth 1 -print -quit) ]]; then
  pass "private intermediates are cleaned after success"
else
  fail "private intermediates are cleaned after success"
fi

failure_dir="$TEST_ROOT/failure case"
failure_run_dir="$failure_dir/run directory"
failure_temp_root="$failure_dir/temp root"
mkdir -p "$failure_run_dir" "$failure_temp_root"
failure_input="$failure_run_dir/input keystore.jks"
failure_output="$failure_run_dir/output keystore.jks"
failure_log="$failure_dir/keytool.log"
: > "$failure_input"

set +e
(
  cd "$failure_run_dir"
  PATH="$stub_dir:$PATH" \
    TMPDIR="$failure_temp_root" \
    KEYSTORE_PASS="$sentinel" \
    KEYTOOL_LOG="$failure_log" \
    KEYTOOL_STATE="$failure_dir/keytool.state" \
    KEYTOOL_FAIL_CALL=2 \
    STUB_EXPECTED_PASS="$sentinel" \
    "$SCRIPT_UNDER_TEST" "release alias" "$failure_input" "$failure_output"
) > "$failure_dir/stdout" 2> "$failure_dir/stderr"
failure_status=$?
set -e

if [[ $failure_status -ne 0 ]] \
  && [[ -s $failure_log ]] \
  && grep -Fq "ARG:$failure_temp_root/" "$failure_log" \
  && [[ -z $(find "$failure_temp_root" -mindepth 1 -print -quit) ]]; then
  pass "private intermediates are cleaned after keytool failure"
else
  fail "private intermediates are cleaned after keytool failure"
fi

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
