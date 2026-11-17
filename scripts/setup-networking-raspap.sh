#!/bin/bash
set -e

# Chroot-safe service enable/disable (no running systemd)
mkdir -p /etc/systemd/system/multi-user.target.wants

# The SIM selection unit comes from citronics-lime-<board>
systemctl enable msm-modem-uim-selection

# DHCP, on the WiFi access point and on the USB link, is RaspAP's dnsmasq:
# the image has no isc-dhcp-server. citronics-usb-network writes the USB
# link's part (/etc/dnsmasq.d/080_usb0.conf) at boot.
