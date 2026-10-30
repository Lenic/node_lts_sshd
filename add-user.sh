#!/bin/sh
# Create a user with zsh as the login shell; .zshrc and other configs are copied from /etc/skel
# Usage: ./add-user.sh [-u uid] <username> [full name], e.g. ./add-user.sh -u 1000 lenic "Lenic Rayleigh"
# Pin the UID with -u so files on a persistent /home volume keep matching owners across containers
set -e

usage() {
    echo "Usage: $0 [-u uid] <username> [full name]" >&2
    exit 1
}

uid=
while getopts "u:" opt; do
    case "$opt" in
        u) uid=$OPTARG ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[ -n "$1" ] || usage

set -- -s /bin/zsh ${uid:+-u "$uid"} ${2:+-g "$2"} "$1"
adduser "$@"
