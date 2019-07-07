#!/bin/bash
set -exuo pipefail

KEYCHAIN_FILE="$TEMPDIR/dontcare.keychain-db"

security create-keychain -p "$CERT_PASSWORD" "$KEYCHAIN_FILE"
security default-keychain -s dontcare.keychain
security unlock-keychain -p "$CERT_PASSWORD" "$KEYCHAIN_FILE"
security set-key-partition-list -S apple-tool:,apple: -s -k "$CERT_PASSWORD" "$KEYCHAIN_FILE"

security import $TEMPDIR/developer.p12 -k "$KEYCHAIN_FILE" -P "$CERT_PASSWORD" -A
security import $TEMPDIR/distribution.p12 -k "$KEYCHAIN_FILE" -P "$CERT_PASSWORD" -A
