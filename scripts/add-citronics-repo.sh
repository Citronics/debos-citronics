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

echo "Citronics APT repository added"
