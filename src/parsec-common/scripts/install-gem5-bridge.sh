#!/bin/bash
# Runs as root in the guest. ISA=x86|arm64.
# Builds m5/libm5 from the uploaded gem5-pm tree so the guest's hypercall ABI
# matches the simulator.
set -eu

src=/home/gem5/gem5
mkdir -p "$src"
tar -xzf /home/gem5/gem5-src.tar.gz -C "$src"

cp -r "$src/include/gem5" /usr/local/include/
# Native build: drop the ABI's default cross prefix (arm64 sets aarch64-linux-gnu-).
(cd "$src/util/m5" && scons "$ISA.CROSS_COMPILE=" "build/$ISA/out/m5")
cp "$src/util/m5/build/$ISA/out/m5" /usr/local/bin/gem5-bridge
cp "$src/util/m5/build/$ISA/out/libm5.a" /usr/local/lib/
chmod 4755 /usr/local/bin/gem5-bridge
ln -sf /usr/local/bin/gem5-bridge /usr/local/bin/m5

if [ "$ISA" = x86 ]; then
    kver=$(uname -r)
    # The Makefile's M=$(PWD) needs a real cwd; make -C does not update PWD.
    (cd "$src/util/gem5_bridge" && make build install)
else
    # Prebuilt by arm-parsec/build-kernel.sh against the shipped vmlinux.
    kver=6.8.12
    cp -r /home/gem5/modules/lib/modules/. /lib/modules/
fi
depmod -a "$kver"
# The m5 source tree stays: install-parsec.sh links against its libm5.a.
