#!/bin/bash

# Security-enhanced Android keystore conversion script
# Usage: [KEYSTORE_PASS=...] ./convert-android-keystore.sh <alias> <input_keystore> <output_keystore>

set -e

if [[ $# -eq 4 ]]; then
  # Backward compatibility for 4 arguments, but warn about insecurity
  KEY_ALIAS="$1"
  export KEYSTORE_PASS="$2"
  KEYSTORE_IN="$3"
  KEYSTORE_OUT="$4"
  echo "Warning: Passing password as an argument is insecure. Use KEYSTORE_PASS environment variable instead."
elif [[ $# -eq 3 ]]; then
  KEY_ALIAS="$1"
  KEYSTORE_IN="$2"
  KEYSTORE_OUT="$3"
else
  echo "Usage: [KEYSTORE_PASS=...] $0 <alias> <input_keystore> <output_keystore>"
  exit 1
fi

if [[ -z "${KEYSTORE_PASS}" ]]; then
  read -rs -p "Enter keystore password: " KEYSTORE_PASS
  echo
  export KEYSTORE_PASS
fi

# Use mktemp for secure temporary files
CERT_FILE=$(mktemp)
P12_FILE=$(mktemp)

# Ensure temporary files are cleaned up on exit
trap 'rm -f "$CERT_FILE" "$P12_FILE"' EXIT

# Export certificate
# Use -storepass:env to avoid exposing password in process list
keytool -exportcert \
  -alias "$KEY_ALIAS" \
  -keystore "$KEYSTORE_IN" \
  -storepass:env KEYSTORE_PASS \
  -rfc \
  -file "$CERT_FILE"

# Export to PKCS#12
keytool -importkeystore \
  -srckeystore "$KEYSTORE_IN" \
  -srcalias "$KEY_ALIAS" \
  -srcstorepass:env KEYSTORE_PASS \
  -destkeystore "$P12_FILE" \
  -deststoretype PKCS12 \
  -deststorepass:env KEYSTORE_PASS

# Import into new JKS keystore
keytool -importkeystore \
  -destkeystore "$KEYSTORE_OUT" \
  -deststoretype JKS \
  -deststorepass:env KEYSTORE_PASS \
  -srckeystore "$P12_FILE" \
  -srcstoretype PKCS12 \
  -srcstorepass:env KEYSTORE_PASS \
  -alias "$KEY_ALIAS"

keytool -list -v -keystore "$KEYSTORE_OUT" -storepass:env KEYSTORE_PASS
