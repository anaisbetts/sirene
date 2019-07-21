#!/bin/bash
set -euxo pipefail

KEYCHAIN_FILE="$TEMPDIR/dontcare.keychain"

security create-keychain -p "$CERT_PASSWORD" "$KEYCHAIN_FILE"
security default-keychain -s "$KEYCHAIN_FILE"
security unlock-keychain -p "$CERT_PASSWORD" "$KEYCHAIN_FILE"

security import $TEMPDIR/developer.p12 -k "$KEYCHAIN_FILE" -P "$CERT_PASSWORD" -A
security import $TEMPDIR/distribution.p12 -k "$KEYCHAIN_FILE" -P "$CERT_PASSWORD" -A

security set-keychain-settings -t 3600 -u "$KEYCHAIN_FILE"
security list-keychains -s "$KEYCHAIN_FILE"

## NB: We need this for some reason, or else macOS (despite us already unlocking the keychain),
## will open a modal dialog and park the builder forever
security set-key-partition-list -S apple-tool:,apple: -s -k "$CERT_PASSWORD" "$KEYCHAIN_FILE"