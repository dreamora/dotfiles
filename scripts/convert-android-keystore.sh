#!/bin/bash

# Security Standard: Exit immediately if a command fails
set -e

KEY_ALIAS="$1"
KEYSTORE_PASS="$2"
KEYSTORE_IN="$3"
KEYSTORE_OUT="$4"

# Security Standard: Passwords should be passed via environment variables
# scoped directly to the command to prevent them from appearing in the process list
# or being exposed to other processes.

# Create a secure temporary directory for intermediate files
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

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
