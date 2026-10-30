#!/bin/sh
# Create a user with zsh as the login shell; .zshrc and other configs are copied from /etc/skel
# Usage: ./add-user.sh <username> [full name], e.g. ./add-user.sh lenic "Lenic Rayleigh"
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <username> [full name]" >&2
    exit 1
fi

if [ -n "$2" ]; then
    adduser -s /bin/zsh -g "$2" "$1"
else
    adduser -s /bin/zsh "$1"
fi
