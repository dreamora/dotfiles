#!/bin/bash

# Script to convert an Android keystore to a different format
# Usage: ./convert-android-keystore.sh <alias> <password> <input_keystore> <output_keystore>

set -e

if [ $# -ne 4 ]; then
    echo "Usage: $0 <alias> <password> <input_keystore> <output_keystore>"
    exit 1
fi

KEY_ALIAS="$1"
KEYSTORE_PASS="$2"
KEYSTORE_IN="$3"
KEYSTORE_OUT="$4"

# Create a secure temporary directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Security Standard: Passwords should be passed via environment variables
# to prevent them from appearing in the process list.
# We scope the variable to each command instead of exporting it globally.

# Export certificate
KS_PASS="$KEYSTORE_PASS" keytool -exportcert \
  -alias "$KEY_ALIAS" \
  -keystore "$KEYSTORE_IN" \
  -storepass:env KS_PASS \
  -rfc \
  -file "$TMP_DIR/certificate.pem"

# Export to PKCS#12
KS_PASS="$KEYSTORE_PASS" keytool -importkeystore \
  -srckeystore "$KEYSTORE_IN" \
  -srcalias "$KEY_ALIAS" \
  -srcstorepass:env KS_PASS \
  -destkeystore "$TMP_DIR/keystore.p12" \
  -deststoretype PKCS12 \
  -deststorepass:env KS_PASS

# Import into new JKS keystore
KS_PASS="$KEYSTORE_PASS" keytool -importkeystore \
  -destkeystore "$KEYSTORE_OUT" \
  -deststoretype JKS \
  -deststorepass:env KS_PASS \
  -srckeystore "$TMP_DIR/keystore.p12" \
  -srcstoretype PKCS12 \
  -srcstorepass:env KS_PASS \
  -alias "$KEY_ALIAS"

KS_PASS="$KEYSTORE_PASS" keytool -list -v -keystore "$KEYSTORE_OUT" -storepass:env KS_PASS

echo "Keystore conversion completed successfully."
