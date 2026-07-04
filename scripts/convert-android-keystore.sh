#!/usr/bin/env bash

set -euo pipefail

# Check if the correct number of arguments is provided
if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <key_alias> <keystore_pass> <keystore_in> <keystore_out>"
  exit 1
fi

KEY_ALIAS="$1"
KEYSTORE_PASS="$2"
KEYSTORE_IN="$3"
KEYSTORE_OUT="$4"

# Create a secure temporary directory
TMP_DIR=$(mktemp -d)

# Ensure cleanup on exit
trap 'rm -rf "$TMP_DIR"; unset KS_PASS' EXIT

# Security Standard: Passwords should be passed via environment variables
# to prevent them from appearing in the process list.
export KS_PASS="$KEYSTORE_PASS"

# Export certificate
# Note: keytool does not support -- delimiter
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

keytool -list -v -keystore "$KEYSTORE_OUT" -storepass:env KS_PASS
