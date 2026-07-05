#!/usr/bin/env bash

# Hardened Android Keystore Conversion Script
# This script converts an Android Keystore to JKS format using intermediate PKCS12.

set -euo pipefail

usage() {
  echo "Usage: [KS_PASS=password] $0 <alias> [password] <keystore_in> <keystore_out>"
  echo "Note: Providing password as an argument is less secure than using KS_PASS environment variable."
  exit 1
}

# Security Standard: Passwords should preferably be passed via environment variables
# (KS_PASS) to prevent them from appearing in the process list.
KEY_ALIAS="${1:-}"
KEYSTORE_PASS="${KS_PASS:-}"

case $# in
  3)
    [[ -n "$KEYSTORE_PASS" ]] || usage
    KEYSTORE_IN="${2:-}"
    KEYSTORE_OUT="${3:-}"
    ;;
  4)
    KEYSTORE_PASS="${KEYSTORE_PASS:-${2:-}}"
    KEYSTORE_IN="${3:-}"
    KEYSTORE_OUT="${4:-}"
    ;;
  *)
    usage
    ;;
esac

if [[ -z "$KEY_ALIAS" || -z "$KEYSTORE_PASS" || -z "$KEYSTORE_IN" || -z "$KEYSTORE_OUT" ]]; then
  usage
fi

# Export KS_PASS for keytool to use via -storepass:env
export KS_PASS="$KEYSTORE_PASS"

# Create a secure temporary directory for intermediate files.
# This prevents symlink attacks and race conditions in shared directories.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"; unset KS_PASS' EXIT

# Export certificate
keytool -exportcert \
  -alias "$KEY_ALIAS" \
  -keystore "$KEYSTORE_IN" \
  -storepass:env KS_PASS \
  -rfc \
  -file "$TMP_DIR/certificate.pem"

# Export to PKCS#12
keytool -importkeystore \
  -srckeystore "$KEYSTORE_IN" \
  -srcalias "$KEY_ALIAS" \
  -srcstorepass:env KS_PASS \
  -destkeystore "$TMP_DIR/keystore.p12" \
  -deststoretype PKCS12 \
  -deststorepass:env KS_PASS

# Import into new JKS keystore
keytool -importkeystore \
  -destkeystore "$KEYSTORE_OUT" \
  -deststoretype JKS \
  -deststorepass:env KS_PASS \
  -srckeystore "$TMP_DIR/keystore.p12" \
  -srcstoretype PKCS12 \
  -srcstorepass:env KS_PASS \
  -alias "$KEY_ALIAS"

# List the contents of the new keystore to verify
keytool -list -v -keystore "$KEYSTORE_OUT" -storepass:env KS_PASS
