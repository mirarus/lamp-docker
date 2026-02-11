###############################################
# All-in-One LAMP Image
# Apache 2.4 / OpenLiteSpeed + PHP (selectable)
# + MariaDB 10.5
#
# Build with custom PHP version:
#   docker build --build-arg PHP_VERSION=8.1 .
#
# Supported: 7.3, 7.4, 8.0, 8.1, 8.2, 8.3
#
# Each service in its own directory:
#   php/        - PHP setup + config
#   apache/     - Apache setup + config
#   litespeed/  - OpenLiteSpeed setup + config
#   mariadb/    - MariaDB setup + config
#   phpmyadmin/ - phpMyAdmin setup + config
#   redis/      - Redis setup + config
#   ftp/        - vsftpd setup + config
###############################################
FROM debian:bullseye-slim

ARG PHP_VERSION=7.3

ENV DEBIAN_FRONTEND=noninteractive \
    PHP_VERSION=${PHP_VERSION} \
    WEB_SERVER=apache \
    PMA_ENABLED=true \
    PMA_ADMIN_USER=pma_admin \
    PMA_ADMIN_PASS=pma_admin \
    REDIS_ENABLED=true \
    FTP_ENABLED=false \
    FTP_USER=root \
    FTP_PASS=root

# ===== Base packages + Sury PHP repo =====
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg lsb-release supervisor procps \
    && curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ bullseye main" \
        > /etc/apt/sources.list.d/sury-php.list \
    && apt-get update

# ===== Apache install =====
COPY ./apache/install.sh /tmp/apache-install.sh
RUN sed -i 's/\r$//' /tmp/apache-install.sh && chmod +x /tmp/apache-install.sh && /tmp/apache-install.sh

# ===== OpenLiteSpeed install =====
COPY ./litespeed/install.sh /tmp/litespeed-install.sh
RUN sed -i 's/\r$//' /tmp/litespeed-install.sh && chmod +x /tmp/litespeed-install.sh && /tmp/litespeed-install.sh

# ===== PHP install =====
COPY ./php/install.sh /tmp/php-install.sh
RUN sed -i 's/\r$//' /tmp/php-install.sh && chmod +x /tmp/php-install.sh && /tmp/php-install.sh

# ===== MariaDB install =====
COPY ./mariadb/install.sh /tmp/mariadb-install.sh
RUN sed -i 's/\r$//' /tmp/mariadb-install.sh && chmod +x /tmp/mariadb-install.sh && /tmp/mariadb-install.sh

# ===== phpMyAdmin install =====
COPY ./phpmyadmin/install.sh /tmp/phpmyadmin-install.sh
RUN sed -i 's/\r$//' /tmp/phpmyadmin-install.sh && chmod +x /tmp/phpmyadmin-install.sh && /tmp/phpmyadmin-install.sh

# ===== Redis install =====
COPY ./redis/install.sh /tmp/redis-install.sh
RUN sed -i 's/\r$//' /tmp/redis-install.sh && chmod +x /tmp/redis-install.sh && /tmp/redis-install.sh

# ===== FTP install =====
COPY ./ftp/install.sh /tmp/ftp-install.sh
RUN sed -i 's/\r$//' /tmp/ftp-install.sh && chmod +x /tmp/ftp-install.sh && /tmp/ftp-install.sh

# ===== Cleanup =====
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ===== Log directories =====
RUN mkdir -p /var/log/apache2 /var/log/mysql /var/log/php /var/log/ftp /var/log/phpmyadmin /var/log/redis \
    /usr/local/lsws/logs \
    && chown mysql:mysql /var/log/mysql \
    && chown redis:redis /var/log/redis \
    && chown www-data:www-data /var/log/php

# ===== PHP config =====
COPY ./php/*.ini /etc/php/${PHP_VERSION}/fpm/conf.d/

# ===== Apache config =====
COPY ./apache/httpd-vhost.conf /etc/apache2/sites-available/app.conf
COPY ./apache/phpmyadmin.conf  /etc/apache2/conf-available/phpmyadmin.conf
RUN a2ensite app && a2enconf phpmyadmin

# ===== MariaDB config =====
COPY ./mariadb/custom.cnf /etc/mysql/conf.d/custom.cnf
RUN chmod 644 /etc/mysql/conf.d/custom.cnf

# ===== phpMyAdmin config =====
COPY ./phpmyadmin/config.inc.php /opt/phpmyadmin/config.inc.php

# ===== OpenLiteSpeed config =====
COPY ./litespeed/httpd_config.conf /usr/local/lsws/conf/httpd_config.conf
COPY ./litespeed/vhconf.conf /usr/local/lsws/conf/vhosts/app/vhconf.conf

# ===== Redis config =====
COPY ./redis/redis.conf /etc/redis/redis.conf

# ===== FTP config =====
COPY ./ftp/vsftpd.conf /etc/vsftpd.conf

# ===== Supervisord + Entrypoint =====
COPY ./supervisord.conf /etc/supervisor/conf.d/lamp.conf
COPY ./entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# ===== Set PHP-FPM version in supervisord =====
RUN sed -i "s|php-fpmPHP_VERSION|php-fpm${PHP_VERSION}|" /etc/supervisor/conf.d/lamp.conf

# ===== Strip CRLF from all config files =====
RUN find /etc/php /etc/apache2/sites-available /etc/apache2/conf-available \
        /etc/mysql/conf.d /etc/supervisor/conf.d /etc/vsftpd.conf \
        /usr/local/lsws/conf \
        -type f 2>/dev/null | xargs sed -i 's/\r$//' 2>/dev/null || true

# ===== Default web root =====
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

EXPOSE 80 7080 3306 6379 21

WORKDIR /var/www/html

ENTRYPOINT ["/entrypoint.sh"]
