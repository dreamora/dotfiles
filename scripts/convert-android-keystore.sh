#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 KEY_ALIAS KEYSTORE_PASS KEYSTORE_IN KEYSTORE_OUT" >&2
  exit 1
fi

key_alias=$1
keystore_pass=$2
keystore_in=$3
keystore_out=$4

if [[ ! -f "$keystore_in" ]]; then
  echo "Error: input keystore '$keystore_in' does not exist." >&2
  exit 2
fi

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf -- "$tmp_dir"
  unset KS_PASS
}
trap cleanup EXIT

run_keytool() {
  KS_PASS=$keystore_pass keytool "$@"
}

# Export certificate
run_keytool -exportcert \
  -alias "$key_alias" \
  -keystore "$keystore_in" \
  -storepass:env KS_PASS \
  -rfc \
  -file "$tmp_dir/certificate.pem"

# Export to PKCS#12
run_keytool -importkeystore \
  -srckeystore "$keystore_in" \
  -srcalias "$key_alias" \
  -srcstorepass:env KS_PASS \
  -destkeystore "$tmp_dir/keystore.p12" \
  -deststoretype PKCS12 \
  -deststorepass:env KS_PASS

# Import into new JKS keystore
run_keytool -importkeystore \
  -destkeystore "$keystore_out" \
  -deststoretype JKS \
  -deststorepass:env KS_PASS \
  -srckeystore "$tmp_dir/keystore.p12" \
  -srcstoretype PKCS12 \
  -srcstorepass:env KS_PASS \
  -alias "$key_alias"

run_keytool -list -v -keystore "$keystore_out" -storepass:env KS_PASS
