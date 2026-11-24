#!/bin/bash
set -euo pipefail
# The codename suite holds the packages built for this release only
# (e.g. the patched ModemManager)
. /etc/os-release

cat > /etc/apt/sources.list.d/citronics.sources << EOF
Types: deb
URIs: https://citronics.github.io/deb-packages
Suites: stable $VERSION_CODENAME
Components: main
Trusted: yes
EOF

# Pin the patched ModemManager before the image installs it. The same file,
# byte for byte, comes with citronics-lime-*, which then owns it.
mkdir -p /etc/apt/preferences.d
cat > /etc/apt/preferences.d/citronics-modemmanager << 'EOF'
# Keep the Citronics ModemManager (patched for the Fairphone modems): the
# distribution's build crashes at every start after the first and cannot set
# the modem's attach APN. It wins on its version alone only until the
# distribution publishes a higher one, so pin it to this repository.
Package: modemmanager libmm-glib0
Pin: origin citronics.github.io
Pin-Priority: 990
EOF

echo "Citronics APT repository added"
