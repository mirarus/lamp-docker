#!/bin/bash
# OpenLiteSpeed installation
set -e

# Add LiteSpeed repository (official method)
wget -qO - https://repo.litespeed.sh | bash

apt-get update
apt-get install -y --no-install-recommends openlitespeed

# Create vhost directory structure
mkdir -p /usr/local/lsws/conf/vhosts/app

# Set admin password
/usr/local/lsws/admin/misc/admpass.sh <<EOF
admin
OLS@dmin2026
OLS@dmin2026
EOF

# Ensure log directory exists
mkdir -p /usr/local/lsws/logs

echo "[install] OpenLiteSpeed installed."
