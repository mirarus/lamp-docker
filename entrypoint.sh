#!/bin/bash
set -e

PMA_ENABLED="${PMA_ENABLED:-true}"
PMA_ADMIN_USER="${PMA_ADMIN_USER:-pma_admin}"
PMA_ADMIN_PASS="${PMA_ADMIN_PASS:-Pma@dmin2026}"
FTP_ENABLED="${FTP_ENABLED:-false}"
FTP_USER="${FTP_USER:-dev}"
FTP_PASS="${FTP_PASS:-dev123}"

# ===== phpMyAdmin toggle =====
if [ "$PMA_ENABLED" = "false" ]; then
    a2disconf phpmyadmin 2>/dev/null || true
    echo "[entrypoint] phpMyAdmin disabled."
else
    a2enconf phpmyadmin 2>/dev/null || true
fi

# ===== FTP toggle =====
if [ "$FTP_ENABLED" = "true" ]; then
    # Create FTP user if not exists
    if ! id "$FTP_USER" > /dev/null 2>&1; then
        useradd -m -d /var/www/html -s /usr/sbin/nologin "$FTP_USER"
    fi
    echo "$FTP_USER:$FTP_PASS" | chpasswd
    # Grant vsftpd access to web root
    chown "$FTP_USER":www-data /var/www/html
    # Enable vsftpd in supervisord
    sed -i '/\[program:vsftpd\]/,/^$/{s/autostart=false/autostart=true/}' \
        /etc/supervisor/conf.d/lamp.conf
    echo "[entrypoint] FTP enabled. User: $FTP_USER"
else
    echo "[entrypoint] FTP disabled."
fi

# ===== MariaDB first-run initialization =====
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[entrypoint] MariaDB first-run setup starting..."

    # Initialize data directory
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1

    # Start temporary MariaDB (no network, socket only)
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    MYSQL_PID=$!

    # Wait for MariaDB to become ready
    for i in $(seq 1 30); do
        if mysqladmin ping --socket=/run/mysqld/mysqld.sock > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    echo "[entrypoint] Setting up root security + PMA users..."

    # Root security + PMA users
    mysql --socket=/run/mysqld/mysqld.sock -u root <<-EOSQL
        -- Root security hardening
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

        -- phpMyAdmin configuration storage
        CREATE DATABASE IF NOT EXISTS \`phpmyadmin\`;
        CREATE USER IF NOT EXISTS 'pma'@'%' IDENTIFIED BY 'pmapass';
        GRANT SELECT, INSERT, UPDATE, DELETE ON \`phpmyadmin\`.* TO 'pma'@'%';

        -- phpMyAdmin admin user
        CREATE USER IF NOT EXISTS '${PMA_ADMIN_USER}'@'%' IDENTIFIED BY '${PMA_ADMIN_PASS}';
        GRANT ALL PRIVILEGES ON *.* TO '${PMA_ADMIN_USER}'@'%' WITH GRANT OPTION;

        FLUSH PRIVILEGES;
EOSQL

    # Run init SQL files (sorted order)
    # Database, user and table creation is handled entirely by these SQL files
    for f in /docker-entrypoint-initdb.d/*.sql; do
        if [ -f "$f" ]; then
            echo "[entrypoint] Loading SQL: $(basename $f)"
            mysql --socket=/run/mysqld/mysqld.sock -u root < "$f"
        fi
    done

    echo "[entrypoint] MariaDB first-run setup completed."

    # Stop temporary MariaDB
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root shutdown
    wait $MYSQL_PID 2>/dev/null || true
fi

echo "[entrypoint] Starting services..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/lamp.conf
