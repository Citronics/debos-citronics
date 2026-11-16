#!/bin/bash
# Lime carrier: the Limeboard header tools (limeboard-io: limeboard-config,
# the GPIO libraries, the udev rules, the STM32 firmware) and the Home
# Assistant agent (limeboard-ha) come from citronics-lime-<board>. This adds
# what an image wants on top: the packages they recommend, and the image's
# user in the groups that own the header (gpio, spi, i2c) and /dev/serial0
# (dialout), as on a Raspberry Pi.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends can-utils iproute2

# The header itself needs limeboard-io, which only boards with Limeboard
# support (citronics-lime-fp2) install: the RPi.GPIO compatibility, and the
# groups it creates.
if dpkg-query -W -f='${Status}' limeboard-io 2>/dev/null | grep -q "ok installed"; then
	apt-get install -y --no-install-recommends python3-rpi-lgpio
	for user in $(getent group sudo | cut -d: -f4 | tr , ' '); do
		usermod -aG gpio,spi,i2c,dialout "$user"
	done
fi

echo "Lime carrier setup done"
