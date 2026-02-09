#!/bin/bash
# Redis server installation
set -e

apt-get install -y --no-install-recommends redis-server

mkdir -p /var/log/redis /var/lib/redis
chown redis:redis /var/log/redis /var/lib/redis

echo "[install] Redis installed."
