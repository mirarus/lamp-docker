#!/bin/bash
# OpenLiteSpeed installation
set -e

# Add OpenLiteSpeed repository
curl -sSL https://rpms.litespeedtech.com/debian/lst_debian_repo.gpg \
    | gpg --dearmor -o /usr/share/keyrings/openlitespeed.gpg

echo "deb [signed-by=/usr/share/keyrings/openlitespeed.gpg] http://rpms.litespeedtech.com/debian/ bullseye main" \
    > /etc/apt/sources.list.d/openlitespeed.list

apt-get update
apt-get install -y --no-install-recommends openlitespeed

# Create vhost directory structure
mkdir -p /usr/local/lsws/conf/vhosts/app

# Set admin password (default, can be changed via env)
ENCRYPT_PASS=$(/usr/local/lsws/admin/fcgi-bin/admin_php -q \
    /usr/local/lsws/admin/misc/htpasswd.php 'OLS@dmin2026')
echo "admin:${ENCRYPT_PASS}" > /usr/local/lsws/admin/conf/htpasswd

# Ensure log directory exists
mkdir -p /usr/local/lsws/logs
chown -R lsadm:lsadm /usr/local/lsws/logs

echo "[install] OpenLiteSpeed installed."
