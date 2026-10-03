#!/bin/bash
# Usage: sudo verify-image.sh <raw-image> <x86|arm64> [vmlinux]
# Mounts the root partition (partition 2) read-only and checks the PARSEC install.
set -eu

image="$1"; isa="$2"; vmlinux="${3:-}"
APPS="blackscholes bodytrack canneal dedup facesim ferret fluidanimate freqmine raytrace streamcluster swaptions vips x264"
CONFIG=gcc-hooks-gem5-fs
case "$isa" in x86) machine="X86-64" ;; arm64) machine="AArch64" ;; esac

mnt=$(mktemp -d)
loop=$(losetup -fP --show "$image")
trap 'umount "$mnt" 2>/dev/null; losetup -d "$loop"; rmdir "$mnt"' EXIT
udevadm settle # partition nodes can appear late
mount -o ro "${loop}p2" "$mnt"

fail() { echo "FAIL: $*" >&2; exit 1; }
parsec="$mnt/home/gem5/parsec-benchmark"

for app in $APPS; do
    bins=$(ls "$parsec"/pkgs/*/"$app"/inst/*."$CONFIG"/bin/* 2>/dev/null) || fail "$app: no binary"
    for bin in $bins; do
        readelf -h "$bin" | grep -q "Machine:.*$machine" || fail "$bin: not $machine"
        grep -aq m5_hypercall_addr "$bin" || fail "$bin: no m5_hypercall_addr"
    done
done

[ -u "$mnt/usr/local/bin/gem5-bridge" ] || fail "gem5-bridge is not setuid"
[ "$(readlink "$mnt/sbin/init")" = /sbin/gem5_init.sh ] || fail "/sbin/init is not gem5_init.sh"

ko=$(find "$mnt/lib/modules" -name gem5_bridge.ko | head -n 1)
[ -n "$ko" ] || fail "gem5_bridge.ko missing"
if [ -n "$vmlinux" ]; then
    kver=$(strings "$vmlinux" | grep -m1 -o 'Linux version [^ ]*' | cut -d' ' -f3)
    modinfo -F vermagic "$ko" | grep -q "^$kver " || fail "vermagic does not match vmlinux $kver"
fi
echo "OK: $image"
