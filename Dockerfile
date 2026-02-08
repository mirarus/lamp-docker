###############################################
# All-in-One LAMP Image
# Apache 2.4 + PHP 7.3-FPM + MariaDB 10.5
#
# Each service in its own directory:
#   php/        - PHP setup + config
#   apache/     - Apache setup + config
#   mariadb/    - MariaDB setup + config
#   phpmyadmin/ - phpMyAdmin setup + config
#   ftp/        - vsftpd setup + config
###############################################
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PMA_ENABLED=true \
    PMA_ADMIN_USER=pma_admin \
    PMA_ADMIN_PASS=pma_admin \
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
RUN chmod +x /tmp/apache-install.sh && /tmp/apache-install.sh

# ===== PHP install =====
COPY ./php/install.sh /tmp/php-install.sh
RUN chmod +x /tmp/php-install.sh && /tmp/php-install.sh

# ===== MariaDB install =====
COPY ./mariadb/install.sh /tmp/mariadb-install.sh
RUN chmod +x /tmp/mariadb-install.sh && /tmp/mariadb-install.sh

# ===== phpMyAdmin install =====
COPY ./phpmyadmin/install.sh /tmp/phpmyadmin-install.sh
RUN chmod +x /tmp/phpmyadmin-install.sh && /tmp/phpmyadmin-install.sh

# ===== FTP install =====
COPY ./ftp/install.sh /tmp/ftp-install.sh
RUN chmod +x /tmp/ftp-install.sh && /tmp/ftp-install.sh

# ===== Cleanup =====
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ===== Log directories =====
RUN mkdir -p /var/log/apache2 /var/log/mysql /var/log/php /var/log/ftp /var/log/phpmyadmin \
    && chown mysql:mysql /var/log/mysql

# ===== PHP config =====
COPY ./php/*.ini /etc/php/7.3/fpm/conf.d/

# ===== Apache config =====
COPY ./apache/httpd-vhost.conf /etc/apache2/sites-available/app.conf
COPY ./apache/phpmyadmin.conf  /etc/apache2/conf-available/phpmyadmin.conf
RUN a2ensite app && a2enconf phpmyadmin

# ===== MariaDB config =====
COPY ./mariadb/custom.cnf /etc/mysql/conf.d/custom.cnf
RUN chmod 644 /etc/mysql/conf.d/custom.cnf

# ===== phpMyAdmin config =====
COPY ./phpmyadmin/config.inc.php /opt/phpmyadmin/config.inc.php

# ===== FTP config =====
COPY ./ftp/vsftpd.conf /etc/vsftpd.conf

# ===== Supervisord + Entrypoint =====
COPY ./supervisord.conf /etc/supervisor/conf.d/lamp.conf
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ===== Default web root =====
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

EXPOSE 80 3306 21

WORKDIR /var/www/html

ENTRYPOINT ["/entrypoint.sh"]
