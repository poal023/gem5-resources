#!/bin/bash
# Runs as root in the guest.
set -eu

apt-get update
apt-get install -y scons git vim build-essential m4 gettext pkg-config \
    x11proto-xext-dev libglu1-mesa-dev libxi-dev libxmu-dev libx11-dev \
    libxext-dev libssl-dev

# x86 builds gem5_bridge.ko against the distro kernel it also ships to gem5.
if [ "$ISA" = x86 ]; then
    apt-get install -y "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"
fi

mv /home/gem5/serial-getty@.service /lib/systemd/system/

mv /home/gem5/gem5_init.sh /sbin
chmod 755 /sbin/gem5_init.sh
mv /sbin/init /sbin/init.old
ln -s /sbin/gem5_init.sh /sbin/init

# after_boot.sh runs when the gem5 user auto-logs in.
cat >> /home/gem5/.bashrc <<'EOF'

if [ -z "$AFTER_BOOT_EXECUTED" ]; then
    export AFTER_BOOT_EXECUTED=1
    /home/gem5/after_boot.sh
fi
EOF

rm -f /etc/update-motd.d/*
