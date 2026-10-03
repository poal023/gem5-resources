#!/bin/bash
# Runs as root in the guest.
for f in /etc/netplan/50-cloud-init.yaml /etc/netplan/00-installer-config.yaml; do
    [ -f "$f" ] && mv "$f" "$f.bak"
done
systemctl disable systemd-networkd-wait-online.service
systemctl mask systemd-networkd-wait-online.service
