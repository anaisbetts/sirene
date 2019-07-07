#!/bin/bash

set -euxo pipefail
j
KEYCHAIN_FILE="$TEMPDIR/dontcare.keychain"

if [[ `uname -s` == 'darwin' ]]; then
	security lock-keychain "$KEYCHAIN_FILE"
	security delete-keychain "$KEYCHAIN_FILE"
fi
