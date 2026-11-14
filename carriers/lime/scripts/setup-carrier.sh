#!/bin/bash
# Lime carrier: the udev rule binding the kernel's dln2 driver to the STM32's
# Limeboard I/O firmware, dfu-util to update it, and the Home Assistant MQTT
# agent (limeboard-ha). The overlay installs them; they are the same files as
# the buildroot-fp2 limeboard-io and limeboard-ha packages.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends python3-paho-mqtt dfu-util

# It holds the MQTT password
chmod 600 /etc/limeboard-ha.conf

# Idle until a broker is set in /etc/limeboard-ha.conf
systemctl enable limeboard-ha.service

echo "Lime carrier setup done"
