#!/bin/bash

security create-keychain -p "$CERT_PASSWORD" dontcare.keychain
security default-keychain -s dontcare.keychain
security unlock-keychain -p "$CERT_PASSWORD" dontcare.keychain

security import $TEMPDIR/developer.p12 -k dontcare.keychain -P "$CERT_PASSWORD" -A
security import $TEMPDIR/distribution.p12 -k dontcare.keychain -P "$CERT_PASSWORD" -A
