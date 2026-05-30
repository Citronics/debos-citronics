#!/bin/bash
set -e
systemctl enable isc-dhcp-server
systemctl enable set-mac-from-serial
systemctl enable msm-modem-uim-selection
