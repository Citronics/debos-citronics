#!/bin/bash
set -e

WEBROOT="/var/www/html"

echo "==> Installing RaspAP..."

# Clone RaspAP with submodules
rm -rf ${WEBROOT}
git clone --recurse-submodules https://github.com/RaspAP/raspap-webgui ${WEBROOT}
git -C ${WEBROOT} submodule update --remote plugins

# Configure lighttpd routing
CONFSRC="${WEBROOT}/config/50-raspap-router.conf"
LTROOT=$(grep "server.document-root" /etc/lighttpd/lighttpd.conf | awk -F '=' '{print $2}' | tr -d " \"")
HTROOT=${WEBROOT/$LTROOT}
HTROOT=$(echo "$HTROOT" | sed -e 's/\/$//')
awk "{gsub(\"/REPLACE_ME\",\"$HTROOT\")}1" $CONFSRC > /tmp/50-raspap-router.conf
cp /tmp/50-raspap-router.conf /etc/lighttpd/conf-available/
ln -sf /etc/lighttpd/conf-available/50-raspap-router.conf /etc/lighttpd/conf-enabled/50-raspap-router.conf

# Enable PHP for lighttpd
lighttpd-enable-mod fastcgi-php

# Copy sudoers rules
cp ${WEBROOT}/installers/raspap.sudoers /etc/sudoers.d/090_raspap
chmod 0440 /etc/sudoers.d/090_raspap

# Create RaspAP configuration directories
mkdir -p /etc/raspap/backups
mkdir -p /etc/raspap/networking
mkdir -p /etc/raspap/hostapd
mkdir -p /etc/raspap/lighttpd
mkdir -p /etc/raspap/system
mkdir -p /etc/raspap/plugins

# Set ownership
chown -R www-data:www-data ${WEBROOT}
chown -R www-data:www-data /etc/raspap

# Copy hostapd control scripts (servicestart.sh only; enablelog/disablelog removed upstream)
cp ${WEBROOT}/installers/servicestart.sh /etc/raspap/hostapd/
chown -c root:root /etc/raspap/hostapd/*.sh
chmod 750 /etc/raspap/hostapd/*.sh

# Copy plugin helper scripts
cp ${WEBROOT}/installers/plugin_helper.sh /etc/raspap/plugins/
chown -c root:root /etc/raspap/plugins/*.sh
chmod 750 /etc/raspap/plugins/*.sh

# Copy system scripts (debuglog + install loader)
cp ${WEBROOT}/installers/debuglog.sh /etc/raspap/system/
cp ${WEBROOT}/installers/raspbian.sh /etc/raspap/system/
chown -c root:root /etc/raspap/system/*.sh
chmod 750 /etc/raspap/system/*.sh

# Copy lighttpd control scripts
cp ${WEBROOT}/installers/configport.sh /etc/raspap/lighttpd/
chown -c root:root /etc/raspap/lighttpd/*.sh
chmod 750 /etc/raspap/lighttpd/*.sh

# Install raspapd service (chroot-safe: direct symlink instead of systemctl)
cp ${WEBROOT}/installers/raspapd.service /lib/systemd/system/
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /lib/systemd/system/raspapd.service /etc/systemd/system/multi-user.target.wants/raspapd.service

# Install hostapd@ template service (no enable needed for template units)
cp ${WEBROOT}/installers/hostapd@.service /etc/systemd/system/

# Install and enable dhcpcd service (dhcpcd-base on Debian Bookworm has no service file)
cp ${WEBROOT}/installers/dhcpcd.service /lib/systemd/system/
ln -sf /lib/systemd/system/dhcpcd.service /etc/systemd/system/multi-user.target.wants/dhcpcd.service

# Copy default configurations
cp ${WEBROOT}/config/hostapd.conf /etc/hostapd/hostapd.conf
cp ${WEBROOT}/config/090_raspap.conf /etc/dnsmasq.d/090_raspap.conf
cp ${WEBROOT}/config/090_wlan0.conf /etc/dnsmasq.d/090_wlan0.conf
cp ${WEBROOT}/config/config.php ${WEBROOT}/includes/
cp ${WEBROOT}/config/dhcpcd.conf /etc/dhcpcd.conf
cp ${WEBROOT}/config/defaults.json /etc/raspap/networking/
chown www-data:www-data /etc/raspap/networking/defaults.json

# Copy bridge configuration
cp ${WEBROOT}/config/raspap-bridge-br0.netdev /etc/systemd/network/raspap-bridge-br0.netdev
cp ${WEBROOT}/config/raspap-br0-member-eth0.network /etc/systemd/network/raspap-br0-member-eth0.network

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90_raspap.conf

# Write iptables rules directly (iptables commands don't work in chroot)
mkdir -p /etc/iptables
cat > /etc/iptables/rules.v4 << 'IPTEOF'
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -j MASQUERADE
-A POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
IPTEOF

# Unmask and enable hostapd (chroot-safe: direct symlink manipulation)
# Remove any mask (mask = symlink to /dev/null)
rm -f /etc/systemd/system/hostapd.service
# Enable: create WantedBy symlink
ln -sf /lib/systemd/system/hostapd.service /etc/systemd/system/multi-user.target.wants/hostapd.service

# Optimize PHP - use php8.2 for bookworm
PHP_VERSION="8.2"
if [ -f /etc/php/${PHP_VERSION}/cgi/php.ini ]; then
    sed -i -E 's/^session\.cookie_httponly\s*=\s*(0|([O|o]ff)|([F|f]alse)|([N|n]o))\s*$/session.cookie_httponly = 1/' /etc/php/${PHP_VERSION}/cgi/php.ini
    sed -i -E 's/^;?opcache\.enable\s*=\s*(0|([O|o]ff)|([F|f]alse)|([N|n]o))\s*$/opcache.enable = 1/' /etc/php/${PHP_VERSION}/cgi/php.ini
    phpenmod opcache || true
fi

echo "==> RaspAP installation complete."
