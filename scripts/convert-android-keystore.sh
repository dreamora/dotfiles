#!/bin/bash

KEY_ALIAS=$1
KEYSTORE_PASS=$2
KEYSTORE_IN=$3
KEYSTORE_OUT=$4

# Use environment variables for passwords to avoid exposure in process lists
export KEYSTORE_PASS

# Export certificate
keytool -exportcert \
  -alias "$KEY_ALIAS" \
  -keystore "$KEYSTORE_IN" \
  -storepass:env KEYSTORE_PASS \
  -rfc \
  -file certificate.pem

# Export to PKCS#12
keytool -importkeystore \
  -srckeystore "$KEYSTORE_IN" \
  -srcalias "$KEY_ALIAS" \
  -srcstorepass:env KEYSTORE_PASS \
  -destkeystore keystore.p12 \
  -deststoretype PKCS12 \
  -deststorepass:env KEYSTORE_PASS

# Import into new JKS keystore
keytool -importkeystore \
  -destkeystore "$KEYSTORE_OUT" \
  -deststoretype JKS \
  -deststorepass:env KEYSTORE_PASS \
  -srckeystore keystore.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass:env KEYSTORE_PASS \
  -alias "$KEY_ALIAS"

keytool -list -v -keystore "$KEYSTORE_OUT" -storepass:env KEYSTORE_PASS

# Clean up temporary files
rm certificate.pem keystore.p12

