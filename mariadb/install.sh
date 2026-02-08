#!/bin/bash
# MariaDB installation
set -e

apt-get install -y --no-install-recommends \
    mariadb-server mariadb-client

mkdir -p /run/mysqld /var/log/mysql
chown mysql:mysql /run/mysqld /var/log/mysql

echo "[install] MariaDB installed."
