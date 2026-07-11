#!/bin/bash

KEY_ALIAS=$1
KEYSTORE_PASS=$2
KEYSTORE_IN=$3
KEYSTORE_OUT=$4

# Security Standard: Passwords should be passed via environment variables
# to prevent them from appearing in the process list.
export KS_PASS="$KEYSTORE_PASS"

# Export certificate
keytool -exportcert \
  -alias "$KEY_ALIAS" \
  -keystore "$KEYSTORE_IN" \
  -storepass:env KS_PASS \
  -rfc \
  -file certificate.pem

# Export to PKCS#12
keytool -importkeystore \
  -srckeystore "$KEYSTORE_IN" \
  -srcalias "$KEY_ALIAS" \
  -srcstorepass:env KS_PASS \
  -destkeystore keystore.p12 \
  -deststoretype PKCS12 \
  -deststorepass:env KS_PASS

# Import into new JKS keystore
keytool -importkeystore \
  -destkeystore "$KEYSTORE_OUT" \
  -deststoretype JKS \
  -deststorepass:env KS_PASS \
  -srckeystore keystore.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass:env KS_PASS \
  -alias "$KEY_ALIAS"

keytool -list -v -keystore "$KEYSTORE_OUT" -storepass:env KS_PASS

# Unset sensitive environment variable
unset KS_PASS

# Clean up temporary files
rm certificate.pem keystore.p12

