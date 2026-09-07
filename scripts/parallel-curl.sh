#!/usr/bin/env bash

set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: METHOD=GET $0 <endpoint> [additional curl arguments...]" >&2
  exit 2
fi

readonly endpoint="$1"
shift

readonly method="${METHOD:-GET}"
readonly parallelism="${PARALLELISM:-48}"
readonly duration_seconds="${DURATION_SECONDS:-30}"

run_request() {
  local request_number="$1"
  shift

  curl \
    --silent \
    --show-error \
    --output /dev/null \
    --request "$method" \
    --max-time "$duration_seconds" \
    --write-out "request=${request_number} status=%{http_code} duration=%{time_total}s\n" \
    "$@" \
    "$endpoint"
}

failed=0
request_number=0
pids=()

echo "Starting ${parallelism} parallel requests with a ${duration_seconds}s timeout"

for ((slot = 1; slot <= parallelism; slot++)); do
  ((request_number += 1))
  run_request "$request_number" "$@" &
  pids+=("$!")
done

for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    ((failed += 1))
  fi
done

echo "Completed ${parallelism} requests; curl_failures_or_timeouts=${failed}"

((failed == 0))
