#!/bin/bash
# Apache 2.4 installation
set -e

apt-get install -y --no-install-recommends \
    apache2 libapache2-mod-fcgid brotli

# Enable required modules
a2enmod proxy proxy_fcgi rewrite headers deflate brotli expires setenvif
a2dissite 000-default

# Security hardening
echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
echo "ServerSignature Off" >> /etc/apache2/apache2.conf

echo "[install] Apache 2.4 installed."
