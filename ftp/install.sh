#!/bin/bash
# vsftpd installation
set -e

apt-get install -y --no-install-recommends vsftpd
mkdir -p /var/run/vsftpd/empty /var/log/ftp
touch /var/log/ftp/vsftpd.log /var/log/ftp/xferlog.log

echo "[install] vsftpd installed."
