#!/bin/bash
# Lime carrier: the Home Assistant MQTT agent (limeboard-ha) and dfu-util for
# the board's STM32. The agent is installed by the carrier overlay; it is
# the same file as the buildroot-fp2 limeboard-ha package.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends python3-paho-mqtt python3-serial dfu-util

# It holds the MQTT password
chmod 600 /etc/limeboard-ha.conf

# Idle until a broker is set in /etc/limeboard-ha.conf
systemctl enable limeboard-ha.service

echo "Lime carrier setup done"
