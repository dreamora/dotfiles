#!/usr/bin/env bash

set -euo pipefail

umask 077

usage() {
  printf 'Usage: %s KEY_ALIAS KEYSTORE_IN KEYSTORE_OUT\n' "${0##*/}" >&2
}

if [[ $# -ne 3 ]]; then
  usage
  exit 2
fi

KEY_ALIAS="$1"
KEYSTORE_IN="$2"
KEYSTORE_OUT="$3"

if [[ ! -f $KEYSTORE_IN ]]; then
  printf 'Input keystore does not exist: %s\n' "$KEYSTORE_IN" >&2
  exit 1
fi

keystore_pass="${KEYSTORE_PASS:-}"
unset KEYSTORE_PASS

if [[ -z $keystore_pass ]]; then
  if [[ ! -t 0 ]]; then
    printf 'KEYSTORE_PASS must be set for noninteractive use.\n' >&2
    exit 1
  fi

  printf 'Keystore password: ' >&2
  if ! IFS= read -r -s keystore_pass; then
    printf '\nUnable to read keystore password.\n' >&2
    exit 1
  fi
  printf '\n' >&2

  if [[ -z $keystore_pass ]]; then
    printf 'Keystore password must not be empty.\n' >&2
    exit 1
  fi
fi

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/convert-android-keystore.XXXXXX")"
cleanup() {
  rm -rf -- "$temp_dir"
}
trap cleanup EXIT

certificate="$temp_dir/certificate.pem"
pkcs12_keystore="$temp_dir/keystore.p12"

# Export certificate
KEYSTORE_PASS="$keystore_pass" keytool -exportcert \
  -alias "$KEY_ALIAS" \
  -keystore "$KEYSTORE_IN" \
  -storepass:env KEYSTORE_PASS \
  -rfc \
  -file "$certificate"

# Export to PKCS#12
KEYSTORE_PASS="$keystore_pass" keytool -importkeystore \
  -srckeystore "$KEYSTORE_IN" \
  -srcalias "$KEY_ALIAS" \
  -srcstorepass:env KEYSTORE_PASS \
  -destkeystore "$pkcs12_keystore" \
  -deststoretype PKCS12 \
  -deststorepass:env KEYSTORE_PASS

# Import into new JKS keystore
KEYSTORE_PASS="$keystore_pass" keytool -importkeystore \
  -destkeystore "$KEYSTORE_OUT" \
  -deststoretype JKS \
  -deststorepass:env KEYSTORE_PASS \
  -srckeystore "$pkcs12_keystore" \
  -srcstoretype PKCS12 \
  -srcstorepass:env KEYSTORE_PASS \
  -alias "$KEY_ALIAS"

KEYSTORE_PASS="$keystore_pass" keytool -list -v \
  -keystore "$KEYSTORE_OUT" \
  -storepass:env KEYSTORE_PASS
