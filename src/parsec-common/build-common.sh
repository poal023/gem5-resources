#!/bin/bash
# Sourced by <isa>-parsec/build.sh. Expects to run from that directory.

PACKER_VERSION="1.10.0"
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSEC_ROOT="${PARSEC_ROOT:-$COMMON_DIR/../../../parsec-benchmark}"
GEM5_SRC="${GEM5_SRC:-$COMMON_DIR/../../../gem5-pm}"

fetch_packer() {
    [ -f ./packer ] && return
    case "$(uname -m)" in
        x86_64) local arch=amd64 ;;
        aarch64|arm64) local arch=arm64 ;;
        *) echo "Unsupported host: $(uname -m)" >&2; return 1 ;;
    esac
    local zip="packer_${PACKER_VERSION}_linux_${arch}.zip"
    wget "https://releases.hashicorp.com/packer/${PACKER_VERSION}/${zip}"
    unzip "$zip" packer
    rm "$zip"
}

# Tars the local checkouts so uncommitted hooks/bldconf work ships in the image.
stage_sources() {
    local out="${1:-build}"
    mkdir -p "$out"
    tar -czf "$out/parsec-src.tar.gz" -C "$PARSEC_ROOT/.." \
        --exclude=.git --exclude='*/obj' --exclude='*/inst' --exclude='*/run' \
        --exclude="$(basename "$PARSEC_ROOT")/log" \
        --exclude="$(basename "$PARSEC_ROOT")/gem5_bin" \
        --exclude="$(basename "$PARSEC_ROOT")/*.tar.gz" \
        "$(basename "$PARSEC_ROOT")"
    tar -czf "$out/gem5-src.tar.gz" -C "$GEM5_SRC" \
        --exclude=util/m5/build --exclude='*.o' \
        include util/m5 util/gem5_bridge
}
