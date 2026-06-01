#!/bin/bash
set -euo pipefail

cat > /etc/apt/sources.list.d/citronics.sources << EOF
Types: deb
URIs: https://citronics.github.io/deb-packages
Suites: stable
Components: main
Trusted: yes
EOF

echo "Citronics APT repository added"
