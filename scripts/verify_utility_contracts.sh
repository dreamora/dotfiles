#!/usr/bin/env bash

set -euo pipefail

umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT_UNDER_TEST="$ROOT_DIR/scripts/convert-android-keystore.sh"
SHELL_FUNCTIONS_UNDER_TEST="$ROOT_DIR/homedir/.shellfn"
LINE_EXTRACT_UNDER_TEST="$ROOT_DIR/scripts/line_extract.sh"
DELETE_FILES_UNDER_TEST="$ROOT_DIR/scripts/delete_files.sh"
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

oc_dir="$TEST_ROOT/oc contract"
oc_stub_dir="$oc_dir/stub bin"
oc_work_dir="$oc_dir/work directory"
oc_log="$oc_dir/opencode.log"
oc_marker="$oc_dir/injected"
mkdir -p "$oc_stub_dir" "$oc_work_dir"

cat > "$oc_stub_dir/md5sum" <<'STUB'
#!/usr/bin/env bash
cat >/dev/null
printf '00000000000000000000000000000000  -\n'
STUB

cat > "$oc_stub_dir/lsof" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB

cat > "$oc_stub_dir/opencode" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$OPENCODE_LOG"
STUB

cat > "$oc_stub_dir/tmux" <<'STUB'
#!/usr/bin/env bash
if [[ $1 == has-session ]]; then
  exit 1
fi
if [[ $1 == new-session ]]; then
  command_string="${!#}"
  exec zsh -f -c "PATH=\"\$OC_STUB_DIR:\$PATH\"; $command_string"
fi
exit 2
STUB
chmod +x "$oc_stub_dir"/*

oc_argument='argument with whitespace'
oc_hostile_argument="safe; touch '$oc_marker'"
set +e
PATH="$oc_stub_dir:$PATH" \
  OC_STUB_DIR="$oc_stub_dir" \
  OPENCODE_LOG="$oc_log" \
  SHELL=/usr/bin/true \
  zsh -c 'source "$1"; builtin cd "$2"; oc "$3" "$4"' \
  zsh "$SHELL_FUNCTIONS_UNDER_TEST" "$oc_work_dir" "$oc_argument" "$oc_hostile_argument" \
  > "$oc_dir/stdout" 2> "$oc_dir/stderr"
oc_status=$?
set -e

oc_arguments=()
if [[ -f $oc_log ]]; then
  while IFS= read -r argument; do
    oc_arguments+=("$argument")
  done < "$oc_log"
fi
if [[ $oc_status -eq 0 \
  && ! -e $oc_marker \
  && ${#oc_arguments[@]} -eq 4 \
  && ${oc_arguments[0]} == --port \
  && ${oc_arguments[1]} == 4096 \
  && ${oc_arguments[2]} == "$oc_argument" \
  && ${oc_arguments[3]} == "$oc_hostile_argument" ]]; then
  pass "oc preserves whitespace and command separators as literal arguments"
else
  printf 'oc status=%s marker=%s arguments=%s\n' \
    "$oc_status" "$([[ -e $oc_marker ]] && printf present || printf absent)" "${#oc_arguments[@]}" >&2
  if [[ -s $oc_dir/stderr ]]; then
    sed 's/^/oc stderr: /' "$oc_dir/stderr" >&2
  fi
  for argument in "${oc_arguments[@]}"; do
    printf 'oc argument: %s\n' "$argument" >&2
  done
  fail "oc preserves whitespace and command separators as literal arguments"
fi

line_dir="$TEST_ROOT/line extract"
mkdir -p "$line_dir"
printf 'alpha\n-danger\nomega\n' > "$line_dir/input.txt"
printf 'dash file match\n' > "$line_dir/-input.txt"

if [[ $("$LINE_EXTRACT_UNDER_TEST" '^alpha$' "$line_dir/input.txt") == alpha ]]; then
  pass "line extraction returns normal matches"
else
  fail "line extraction returns normal matches"
fi

if [[ $("$LINE_EXTRACT_UNDER_TEST" '-danger' "$line_dir/input.txt") == -danger ]]; then
  pass "line extraction accepts a dash-leading pattern"
else
  fail "line extraction accepts a dash-leading pattern"
fi

if [[ $(cd "$line_dir" && "$LINE_EXTRACT_UNDER_TEST" 'dash file match' '-input.txt') == 'dash file match' ]]; then
  pass "line extraction accepts a dash-leading filename"
else
  fail "line extraction accepts a dash-leading filename"
fi

set +e
"$LINE_EXTRACT_UNDER_TEST" match "$line_dir/missing.txt" > "$line_dir/missing.stdout" 2> "$line_dir/missing.stderr"
line_missing_status=$?
"$LINE_EXTRACT_UNDER_TEST" absent "$line_dir/input.txt" > "$line_dir/no-match.stdout" 2> "$line_dir/no-match.stderr"
line_no_match_status=$?
set -e

if [[ $line_missing_status -eq 2 ]]; then
  pass "line extraction reports a missing file with status 2"
else
  fail "line extraction reports a missing file with status 2"
fi

if [[ $line_no_match_status -eq 1 && ! -s $line_dir/no-match.stdout && ! -s $line_dir/no-match.stderr ]]; then
  pass "line extraction preserves grep no-match status"
else
  fail "line extraction preserves grep no-match status"
fi

delete_dir="$TEST_ROOT/delete files"
mkdir -p "$delete_dir/normal" "$delete_dir/no match" "$delete_dir/-dash-directory" "$delete_dir/large"
: > "$delete_dir/normal/remove-me.log"
: > "$delete_dir/normal/keep.txt"
: > "$delete_dir/no match/keep.txt"
: > "$delete_dir/-dash-directory/remove-me.log"

if "$DELETE_FILES_UNDER_TEST" remove "$delete_dir/normal" > "$delete_dir/normal.stdout" \
  && [[ ! -e $delete_dir/normal/remove-me.log && -e $delete_dir/normal/keep.txt ]]; then
  pass "file deletion removes matching files and preserves nonmatches"
else
  fail "file deletion removes matching files and preserves nonmatches"
fi

if "$DELETE_FILES_UNDER_TEST" absent "$delete_dir/no match" > "$delete_dir/no-match.stdout" \
  && grep -Fq 'No files found' "$delete_dir/no-match.stdout" \
  && [[ -e $delete_dir/no\ match/keep.txt ]]; then
  pass "file deletion reports an empty match set"
else
  fail "file deletion reports an empty match set"
fi

set +e
"$DELETE_FILES_UNDER_TEST" match "$delete_dir/missing" > "$delete_dir/missing.stdout" 2> "$delete_dir/missing.stderr"
delete_missing_status=$?
set -e
if [[ $delete_missing_status -ne 0 ]]; then
  pass "file deletion rejects a missing directory"
else
  fail "file deletion rejects a missing directory"
fi

find_failure_stub_dir="$delete_dir/find failure stub"
mkdir -p "$find_failure_stub_dir"
cat > "$find_failure_stub_dir/find" <<'STUB'
#!/usr/bin/env bash
exit 42
STUB
chmod +x "$find_failure_stub_dir/find"
set +e
PATH="$find_failure_stub_dir:$PATH" \
  "$DELETE_FILES_UNDER_TEST" match "$delete_dir" \
  > "$delete_dir/find-failure.stdout" 2> "$delete_dir/find-failure.stderr"
find_failure_status=$?
set -e
if [[ $find_failure_status -ne 0 ]] \
  && grep -Fq 'Error: Failed to delete files' "$delete_dir/find-failure.stderr"; then
  pass "file deletion distinguishes find failure from no matches"
else
  fail "file deletion distinguishes find failure from no matches"
fi

if (cd "$delete_dir" && "$DELETE_FILES_UNDER_TEST" remove '-dash-directory') > "$delete_dir/dash.stdout" 2> "$delete_dir/dash.stderr" \
  && [[ ! -e $delete_dir/-dash-directory/remove-me.log ]]; then
  pass "file deletion accepts a dash-leading directory"
else
  fail "file deletion accepts a dash-leading directory"
fi

long_tail="$(printf 'x%.0s' {1..180})"
for index in $(seq 1 600); do
  printf -v sequence '%04d' "$index"
  : > "$delete_dir/large/bulk-$sequence-$long_tail.log"
done
if TMPDIR="$delete_dir/missing-temp-root" \
  "$DELETE_FILES_UNDER_TEST" bulk "$delete_dir/large" > "$delete_dir/large.stdout" \
  && [[ -z $(find "$delete_dir/large" -type f -name '*bulk*' -print -quit) ]]; then
  pass "file deletion drains a large match set without temporary pathname storage"
else
  fail "file deletion drains a large match set without temporary pathname storage"
fi

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
