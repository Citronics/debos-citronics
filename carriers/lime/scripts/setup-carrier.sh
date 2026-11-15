#!/bin/bash
# Lime carrier: for the STM32's Limeboard I/O firmware, which the kernel's
# citronics-dln2 driver runs, the udev rule naming its UART /dev/serial0,
# dfu-util to update it, gpiozero with the "limeboard"
# pin factory, RPi.GPIO and Adafruit Blinka support (limeboard_compat), and
# the Home Assistant MQTT agent (limeboard-ha). The overlay
# installs them; they are the same files as the buildroot-fp2 limeboard-io and
# limeboard-ha packages.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends python3-paho-mqtt python3-psutil python3-spidev dfu-util can-utils

# lgpio, the backend of gpiozero's lgpio pin factory. Built from source:
# Debian does not package it, and its alert thread is patched to wake every
# 10 ms instead of 0.5 ms (about 16% of a CPU on an MSM8974), as in Buildroot.
LGPIO_VERSION=0.2.2.0
LGPIO_URL=https://files.pythonhosted.org/packages/56/33/26ec2e8049eaa2f077bf23a12dc61ca559fbfa7bea0516bf263d657ae275/lgpio-${LGPIO_VERSION}.tar.gz
LGPIO_SHA256=11372e653b200f76a0b3ef8a23a0735c85ec678a9f8550b9893151ed0f863fff
BUILD_DEPS="gcc libc6-dev python3-dev python3-pip python3-setuptools swig"
apt-get install -y --no-install-recommends $BUILD_DEPS
work=$(mktemp -d)
python3 - "$LGPIO_URL" "$LGPIO_SHA256" "$work/lgpio.tar.gz" <<'PY'
import hashlib, sys, urllib.request
url, sha256, dest = sys.argv[1:]
data = urllib.request.urlopen(url).read()
if hashlib.sha256(data).hexdigest() != sha256:
    sys.exit("lgpio: checksum mismatch")
open(dest, "wb").write(data)
PY
tar -xzf "$work/lgpio.tar.gz" -C "$work"
src="$work/lgpio-${LGPIO_VERSION}"
sed -i 's#{0, 5e5}; /\* 0.5 ms timeout \*/#{0, 1e7}; /* 10 ms timeout */#' "$src/src/lgPthAlerts.c"
grep -q '{0, 1e7}' "$src/src/lgPthAlerts.c"
# PYPI=1 links the lg C library into the module. lg's function pointer
# declarations are pre-C23 (the default of GCC 15).
(cd "$src" && PYPI=1 CFLAGS="-std=gnu17" pip3 install --no-deps --no-build-isolation \
	--break-system-packages .)
# gpiozero 2.0.1, the first with the lgpio pin factory (Debian has 1.6.2),
# and rpi-lgpio (RPi.GPIO on lgpio), the same versions as in Buildroot. The
# overlay's limeboard_compat.pth points them at the Limeboard's GPIO chip.
cat > "$work/requirements.txt" <<'REQ'
gpiozero==2.0.1 --hash=sha256:8f621de357171d574c0b7ea0e358cb66e560818a47b0eeedf41ce1cdbd20c70b
colorzero==2.0 --hash=sha256:0e60d743a6b8071498a56465f7719c96a5e92928f858bab1be2a0d606c9aa0f8
rpi-lgpio==0.6 --hash=sha256:0930b6e0ffbfbeee9366fbfa5038d29a7606be96a5229d570b1f81be8f776777
REQ
pip3 install --no-deps --require-hashes --break-system-packages -r "$work/requirements.txt"
rm -rf "$work"
apt-get purge -y --auto-remove $BUILD_DEPS

# It holds the MQTT password
chmod 600 /etc/limeboard-ha.conf

# Idle until a broker is set in /etc/limeboard-ha.conf
systemctl enable limeboard-ha.service

echo "Lime carrier setup done"
