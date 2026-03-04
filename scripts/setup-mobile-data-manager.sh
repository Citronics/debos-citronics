#!/bin/bash
set -e

WEBROOT="/var/www/html"
PLUGIN_DIR="${WEBROOT}/plugins/MobileDataManager"

echo "==> Installing MobileDataManager plugin..."

# Create plugin directory
mkdir -p "${PLUGIN_DIR}/templates/tabs"

# Copy plugin files (placed by overlay action)
cp /var/cache/MobileDataManager/MobileDataManager.php "${PLUGIN_DIR}/"
cp /var/cache/MobileDataManager/manifest.json "${PLUGIN_DIR}/"
cp /var/cache/MobileDataManager/templates/main.php "${PLUGIN_DIR}/templates/"
cp /var/cache/MobileDataManager/templates/tabs/status.php "${PLUGIN_DIR}/templates/tabs/"
cp /var/cache/MobileDataManager/templates/tabs/connection.php "${PLUGIN_DIR}/templates/tabs/"
cp /var/cache/MobileDataManager/templates/tabs/about.php "${PLUGIN_DIR}/templates/tabs/"

# Set ownership
chown -R www-data:www-data "${PLUGIN_DIR}"

# Configure sudoers for the MobileDataManager plugin
cat > /etc/sudoers.d/091_mobile_data_manager << 'SUDOERS'
www-data ALL=(ALL) NOPASSWD:/usr/bin/mmcli *
www-data ALL=(ALL) NOPASSWD:/usr/bin/nmcli connection add *
www-data ALL=(ALL) NOPASSWD:/usr/bin/nmcli connection modify *
www-data ALL=(ALL) NOPASSWD:/usr/bin/nmcli connection up *
www-data ALL=(ALL) NOPASSWD:/usr/bin/nmcli connection down *
www-data ALL=(ALL) NOPASSWD:/usr/bin/nmcli connection delete *
SUDOERS

chmod 0440 /etc/sudoers.d/091_mobile_data_manager

# Clean up staging files
rm -rf /var/cache/MobileDataManager

echo "==> MobileDataManager plugin installed."
