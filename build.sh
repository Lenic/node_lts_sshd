#!/bin/sh
# Build the image, tagged as <alpine version>-<arch>-<date>, e.g. edge-aarch64-20261030
# Builds aarch64 by default; for x86_64 use: ARCH=x86_64 ./build.sh
# Prefers Apple container, then docker; to pick one explicitly use: BUILDER=docker ./build.sh
set -e

IMAGE=${IMAGE:-lenic/node_lts_sshd}
ALPINE_VERSION=edge
ARCH=${ARCH:-aarch64}
DATE=$(date +%Y%m%d)
TAG="${ALPINE_VERSION}-${ARCH}-${DATE}"

case "$ARCH" in
    aarch64) PLATFORM=linux/arm64 ;;
    x86_64) PLATFORM=linux/amd64 ;;
    *) echo "Unsupported ARCH: $ARCH" >&2; exit 1 ;;
esac

if [ -z "$BUILDER" ]; then
    if command -v container >/dev/null 2>&1; then
        BUILDER=container
    elif command -v docker >/dev/null 2>&1; then
        BUILDER=docker
    else
        echo "Neither container nor docker found" >&2
        exit 1
    fi
fi

case "$BUILDER" in
    container)
        # container needs its system services running first
        container system status >/dev/null 2>&1 || container system start
        ;;
    docker) ;;
    *) echo "Unsupported BUILDER: $BUILDER" >&2; exit 1 ;;
esac

"$BUILDER" build --platform "$PLATFORM" -t "${IMAGE}:${TAG}" "$@" .

echo "Built ${IMAGE}:${TAG} with ${BUILDER}"
