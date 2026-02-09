#!/bin/bash
# PHP FPM installation (requires Sury repo)
# Uses PHP_VERSION env var (set by Dockerfile ARG)
set -e

V="${PHP_VERSION:-7.3}"
echo "[install] Installing PHP ${V} FPM..."

# Core packages (all versions)
PACKAGES="php${V}-fpm php${V}-mysql php${V}-gd php${V}-zip \
    php${V}-mbstring php${V}-xml php${V}-curl \
    php${V}-opcache php${V}-apcu php${V}-redis \
    php${V}-intl php${V}-bcmath \
    unzip"

# php-json is separate only for PHP < 8.0
if [ "$(echo "$V < 8.0" | bc -l 2>/dev/null || echo 1)" = "1" ] && dpkg --compare-versions "$V" lt "8.0" 2>/dev/null; then
    PACKAGES="${PACKAGES} php${V}-json"
fi

apt-get install -y --no-install-recommends $PACKAGES bc

mkdir -p /run/php

# ===== Composer =====
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
chmod +x /usr/local/bin/composer
echo "[install] Composer installed."

# ===== ionCube Loader =====
PHP_EXT_DIR="$(php${V} -r 'echo ini_get("extension_dir");')"

curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    | tar xz -C /tmp

IONCUBE_SO="/tmp/ioncube/ioncube_loader_lin_${V}.so"
if [ -f "$IONCUBE_SO" ]; then
    cp "$IONCUBE_SO" "${PHP_EXT_DIR}/ioncube_loader.so"
    echo "zend_extension=ioncube_loader.so" > /etc/php/${V}/mods-available/ioncube.ini
    ln -sf /etc/php/${V}/mods-available/ioncube.ini /etc/php/${V}/fpm/conf.d/00-ioncube.ini
    ln -sf /etc/php/${V}/mods-available/ioncube.ini /etc/php/${V}/cli/conf.d/00-ioncube.ini
    echo "[install] ionCube Loader for PHP ${V} installed."
else
    echo "[install] WARNING: ionCube Loader not available for PHP ${V}, skipping."
fi
rm -rf /tmp/ioncube

# ===== PHP-FPM pool optimization =====
POOL_CONF="/etc/php/${V}/fpm/pool.d/www.conf"

sed -i \
    -e 's/^pm = .*/pm = dynamic/' \
    -e 's/^pm.max_children = .*/pm.max_children = 25/' \
    -e 's/^pm.start_servers = .*/pm.start_servers = 5/' \
    -e 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 3/' \
    -e 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 10/' \
    "$POOL_CONF"

echo "pm.max_requests = 500" >> "$POOL_CONF"
echo "pm.process_idle_timeout = 10s" >> "$POOL_CONF"
echo "request_terminate_timeout = 60s" >> "$POOL_CONF"

# PHP-FPM log settings
echo "php_admin_value[error_log] = /var/log/php/error.log" >> "$POOL_CONF"
echo "php_admin_flag[log_errors] = on" >> "$POOL_CONF"
echo "slowlog = /var/log/php/slow.log" >> "$POOL_CONF"
echo "request_slowlog_timeout = 5s" >> "$POOL_CONF"
echo "catch_workers_output = yes" >> "$POOL_CONF"

# PHP-FPM listen address (localhost for single container)
sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' "$POOL_CONF"

echo "[install] PHP ${V} FPM installed."
