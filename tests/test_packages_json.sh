#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd jq; then
  exit 2
fi

ROOT="$(repo_root)"
JSON="$ROOT/packages.json"
FAILED=0

if jq empty "$JSON" >/dev/null 2>&1; then
  pass "packages.json is valid JSON"
else
  fail "packages.json is invalid JSON" || true
  exit 1
fi

TOP_KEYS=(taps common private entertainment work work-optional)
for key in "${TOP_KEYS[@]}"; do
  if jq -e ". | has(\"$key\")" "$JSON" >/dev/null; then
    pass "top-level key exists: $key"
  else
    fail "missing top-level key: $key" || true
    FAILED=1
  fi
done

PROFILE_KEYS=(brew cask mas npm gem vscode)
PROFILES=(common private entertainment work work-optional)
for profile in "${PROFILES[@]}"; do
  for key in "${PROFILE_KEYS[@]}"; do
    if jq -e ".\"$profile\" | has(\"$key\")" "$JSON" >/dev/null; then
      pass "profile $profile has key $key"
    else
      fail "profile $profile missing key $key" || true
      FAILED=1
    fi
  done
done

if jq -e '.taps | type == "array" and length > 0' "$JSON" >/dev/null; then
  pass "taps is non-empty array"
else
  fail "taps must be a non-empty array" || true
  FAILED=1
fi

for profile in "${PROFILES[@]}"; do
  for kind in brew cask; do
    dups="$(jq -r ".\"$profile\".${kind}[]?.name" "$JSON" | sort | uniq -d || true)"
    if [[ -n "$dups" ]]; then
      fail "duplicate $kind package(s) in profile $profile: $dups" || true
      FAILED=1
    else
      pass "no duplicate $kind packages in profile $profile"
    fi
  done

  for kind in npm gem vscode; do
    dups="$(jq -r ".\"$profile\".${kind}[]?" "$JSON" | sort | uniq -d || true)"
    if [[ -n "$dups" ]]; then
      fail "duplicate $kind entries in profile $profile: $dups" || true
      FAILED=1
    else
      pass "no duplicate $kind entries in profile $profile"
    fi
  done

  invalid_mas="$(jq -r --arg p "$profile" '.[$p].mas[]? | select((.id | type) != "number" or .id <= 0) | .name' "$JSON" || true)"
  if [[ -n "$invalid_mas" ]]; then
    fail "invalid MAS id(s) in profile $profile: $invalid_mas" || true
    FAILED=1
  else
    pass "MAS ids valid in profile $profile"
  fi
done

exit $FAILED
