#!/bin/bash
# Custom init for gem5. With "no_systemd" on the kernel command line it
# drops straight to a gem5 user shell instead of starting systemd.

mount -t proc /proc /proc
mount -t sysfs /sys /sys
cmdline=$(cat /proc/cmdline)

# Non-root PARSEC hooks reach the m5 page through /dev/gem5_bridge.
modprobe gem5_bridge gem5_bridge_baseaddr=0x10010000 gem5_bridge_rangesize=0x10000

printf "Kernel booted, starting gem5 init...\n"
gem5-bridge hypercall 1

if [[ $cmdline == *"no_systemd"* ]]; then
    exec su - gem5
else
    printf "Starting systemd...\n"
    exec /lib/systemd/systemd
fi
