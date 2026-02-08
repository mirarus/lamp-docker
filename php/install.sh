#!/bin/bash
# PHP 7.3 FPM installation (requires Sury repo)
set -e

apt-get install -y --no-install-recommends \
    php7.3-fpm php7.3-mysql php7.3-gd php7.3-zip \
    php7.3-mbstring php7.3-xml php7.3-curl php7.3-json \
    php7.3-opcache php7.3-apcu

mkdir -p /run/php

# PHP-FPM pool optimization
sed -i \
    -e 's/^pm = .*/pm = dynamic/' \
    -e 's/^pm.max_children = .*/pm.max_children = 25/' \
    -e 's/^pm.start_servers = .*/pm.start_servers = 5/' \
    -e 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 3/' \
    -e 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 10/' \
    /etc/php/7.3/fpm/pool.d/www.conf

echo "pm.max_requests = 500" >> /etc/php/7.3/fpm/pool.d/www.conf
echo "pm.process_idle_timeout = 10s" >> /etc/php/7.3/fpm/pool.d/www.conf
echo "request_terminate_timeout = 60s" >> /etc/php/7.3/fpm/pool.d/www.conf

# PHP-FPM listen address (localhost for single container)
sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php/7.3/fpm/pool.d/www.conf

echo "[install] PHP 7.3 FPM installed."
