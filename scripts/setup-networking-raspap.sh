#!/bin/bash
set -e

# Chroot-safe service enable/disable (no running systemd)
mkdir -p /etc/systemd/system/multi-user.target.wants

# Enable modem-related services (same as base setup-networking.sh)
ln -sf /etc/systemd/system/set-mac-from-serial.service /etc/systemd/system/multi-user.target.wants/set-mac-from-serial.service
ln -sf /etc/systemd/system/msm-modem-uim-selection.service /etc/systemd/system/multi-user.target.wants/msm-modem-uim-selection.service

# Disable isc-dhcp-server (RaspAP uses dnsmasq for DHCP)
rm -f /etc/systemd/system/multi-user.target.wants/isc-dhcp-server.service
