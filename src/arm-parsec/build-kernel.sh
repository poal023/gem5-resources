#!/bin/bash
# Builds a mainline 6.8.12 arm64 defconfig kernel plus gem5_bridge.ko without
# Docker. Output: kernel/vmlinux-arm-parsec and kernel/modules/lib/modules/6.8.12.
set -eu
cd "$(dirname "$0")"

VERSION=6.8.12
BASE_URL=https://cdn.kernel.org/pub/linux/kernel/v6.x
GEM5_SRC="${GEM5_SRC:-$PWD/../../../gem5-pm}"
OUT="$PWD/kernel"

if [ "$(uname -m)" != aarch64 ]; then
    export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
fi

mkdir -p "$OUT"
cd "$OUT"
if [ ! -d "linux-$VERSION" ]; then
    wget -nc "$BASE_URL/linux-$VERSION.tar.xz" "$BASE_URL/sha256sums.asc"
    grep " linux-$VERSION.tar.xz\$" sha256sums.asc | sha256sum -c -
    tar -xf "linux-$VERSION.tar.xz"
fi

cd "linux-$VERSION"
make defconfig
make -j"$(nproc)"
make modules_install INSTALL_MOD_PATH="$OUT/modules" INSTALL_MOD_STRIP=1
# The Makefile's M=$(PWD) needs a real cwd; make -C does not update PWD.
(cd "$GEM5_SRC/util/gem5_bridge" && make KMAKEDIR="$OUT/linux-$VERSION" \
    INSTALL_MOD_PATH="$OUT/modules" INSTALL_MOD_STRIP=1 build install)
# Dangling build/source links break packer's directory upload.
rm -f "$OUT/modules/lib/modules/$VERSION/build" "$OUT/modules/lib/modules/$VERSION/source"
cp vmlinux "$OUT/vmlinux-arm-parsec"
