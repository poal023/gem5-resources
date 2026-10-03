#!/bin/bash
set -eu
cd "$(dirname "$0")"
source ../parsec-common/build-common.sh

fetch_packer
stage_sources

# Firmware for the packer VM, padded to the 64 MiB pflash size.
[ -f files/flash0.img ] || {
    dd if=/dev/zero of=files/flash0.img bs=1M count=64
    dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=files/flash0.img conv=notrunc
}

[ -f kernel/vmlinux-arm-parsec ] || bash build-kernel.sh

./packer init arm-parsec.pkr.hcl
./packer build -var "use_kvm=${USE_KVM:-true}" arm-parsec.pkr.hcl
