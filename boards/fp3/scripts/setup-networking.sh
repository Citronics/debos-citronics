#!/bin/bash
set -e
systemctl enable isc-dhcp-server
# DHCP for the USB link is IPv4 only: IPv6 has link-local addresses there, and
# isc-dhcp-server6 has no interface to serve.
systemctl disable isc-dhcp-server6
systemctl enable set-mac-from-serial
systemctl enable msm-modem-uim-selection
