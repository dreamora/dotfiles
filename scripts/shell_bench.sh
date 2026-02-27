#!/usr/bin/env bash
# ===========================================================================
# scripts/shell_bench.sh — Shell startup benchmarking and budget enforcement
#
# Usage:
#   ./scripts/shell_bench.sh              Run benchmark (10 iterations)
#   ./scripts/shell_bench.sh --profile    Include zprof profiling output
#   ./scripts/shell_bench.sh --ci         CI mode: exit non-zero if over budget
#   ./scripts/shell_bench.sh --iterations N  Use N iterations (default: 10)
#
# Startup time budget: 500ms (configurable via SHELL_BENCH_BUDGET_MS)
# ===========================================================================

set -euo pipefail

ITERATIONS=10
PROFILE_MODE=false
CI_MODE=false
BUDGET_MS="${SHELL_BENCH_BUDGET_MS:-500}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)   PROFILE_MODE=true ;;
    --ci)        CI_MODE=true ;;
    --iterations) shift; ITERATIONS="$1" ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

if ! command -v zsh >/dev/null 2>&1; then
  echo "zsh not found — skipping shell benchmark" >&2
  exit 2
fi

echo ""
echo "  Shell Startup Benchmark"
echo "  ========================"
echo "  iterations : $ITERATIONS"
echo "  budget     : ${BUDGET_MS}ms"
echo ""

# --- Capture N timing samples ---
TIMES=()
for i in $(seq 1 "$ITERATIONS"); do
  # time zsh -i -c exit in milliseconds
  ms=$(( $(gdate +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))') ))
  zsh -i -c 'exit' >/dev/null 2>&1 || true
  ms_end=$(( $(gdate +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))') ))
  elapsed=$(( ms_end - ms ))
  TIMES+=("$elapsed")
  printf "  run %-2d: %dms\n" "$i" "$elapsed"
done

# --- Compute min/max/avg ---
MIN="${TIMES[0]}"
MAX="${TIMES[0]}"
SUM=0
for t in "${TIMES[@]}"; do
  SUM=$(( SUM + t ))
  if [ "$t" -lt "$MIN" ]; then MIN="$t"; fi
  if [ "$t" -gt "$MAX" ]; then MAX="$t"; fi
done
AVG=$(( SUM / ITERATIONS ))

echo ""
echo "  --- Results ---"
printf "  min : %dms\n" "$MIN"
printf "  max : %dms\n" "$MAX"
printf "  avg : %dms\n" "$AVG"
printf "  budget : %dms\n" "$BUDGET_MS"
echo ""

if [ "$AVG" -le "$BUDGET_MS" ]; then
  printf "  ✓ PASS: avg %dms is within %dms budget\n" "$AVG" "$BUDGET_MS"
  echo ""
else
  printf "  ✗ OVER BUDGET: avg %dms exceeds %dms budget\n" "$AVG" "$BUDGET_MS"
  echo "  Run with --profile to identify hot paths"
  echo ""
  if [ "$CI_MODE" = true ]; then
    exit 1
  fi
fi

# --- Optional profiling output ---
if [ "$PROFILE_MODE" = true ]; then
  echo "  --- zsh profiling (zprof) ---"
  echo ""
  zsh -i -c 'zprof' 2>/dev/null | head -40 || echo "  zprof not available (add 'zmodload zsh/zprof' to top of .zshrc)"
  echo ""
fi
