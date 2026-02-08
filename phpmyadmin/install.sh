#!/bin/bash
# phpMyAdmin installation
set -e

PMA_VERSION="5.2.1"

curl -sSL "https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz" \
    | tar xz -C /opt

mv "/opt/phpMyAdmin-${PMA_VERSION}-all-languages" /opt/phpmyadmin
mkdir -p /opt/phpmyadmin/tmp
chown -R www-data:www-data /opt/phpmyadmin/tmp

echo "[install] phpMyAdmin ${PMA_VERSION} installed."
