#!/bin/bash

# Generate SSL Certificate
if [ "$SSL_ENABLED" = true ]; then
    /usr/local/bin/generate-cert.sh
fi

# Replace Placeholders in Nginx Configuration File
if [ "$SSL_ENABLED" = true ]; then
    export SSL_SERVER_BLOCK=$(cat /etc/nginx/ssl-server-block.conf | envsubst)
else
    export SSL_SERVER_BLOCK=""
fi
envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start Nginx, MySQL, and PHP-FPM
nginx &
mysqld_safe --datadir='/var/lib/mysql' &
php-fpm81 --nodaemonize