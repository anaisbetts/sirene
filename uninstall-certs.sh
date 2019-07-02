#!/bin/bash

if [[ `uname -s` == 'darwin'' ]]; then
	security lock-keychain dontcare.keychain
	security delete-keychain dontcare.keychain
fi
