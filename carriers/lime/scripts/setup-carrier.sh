#!/bin/bash
# Lime carrier: tools for the board's STM32 (limeboard-mcu) and the Home
# Assistant MQTT agent (limeboard-ha), both installed by the carrier overlay.
# They are the same files as the buildroot-fp2 limeboard-mcu and
# limeboard-ha packages.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends mosquitto-clients dfu-util picocom iproute2

# It holds the MQTT password
chmod 600 /etc/limeboard-ha.conf

# Idle until a broker is set in /etc/limeboard-ha.conf
systemctl enable limeboard-ha.service

echo "Lime carrier setup done"
