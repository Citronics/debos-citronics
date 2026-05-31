#!/bin/bash
set -e

echo "Locking root account..."
passwd -l root 2>/dev/null || echo "Root account already locked"

echo "Creating user 'citro' with password 'citro'..."
useradd -m -s /bin/bash -p "$(openssl passwd -6 citro)" citro

echo "Adding 'citro' to sudo group..."
usermod -aG sudo citro

echo "Setup complete!"
