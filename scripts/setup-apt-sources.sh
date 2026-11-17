#!/bin/bash
# The distribution's APT sources with its security and stable updates, the
# image brought up to date with them, and unattended-upgrades installing
# security updates from then on. debootstrap only configures the release
# itself, which never gets security fixes.
set -euo pipefail

. /etc/os-release
case "$ID" in
debian)
	cat > /etc/apt/sources.list.d/debian.sources << EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: $VERSION_CODENAME $VERSION_CODENAME-updates
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: $VERSION_CODENAME-security
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
	;;
ubuntu)
	cat > /etc/apt/sources.list.d/ubuntu.sources << EOF
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: $VERSION_CODENAME $VERSION_CODENAME-updates $VERSION_CODENAME-security
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
	;;
*)
	echo "Unknown distribution: $ID" >&2
	exit 1
	;;
esac
rm -f /etc/apt/sources.list

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y full-upgrade
apt-get install -y --no-install-recommends unattended-upgrades

echo "APT sources set up for $ID $VERSION_CODENAME, with security updates"
