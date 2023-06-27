#/**
# * *****************************************************************************
# *                        All Rights Reserved
# *
#* Title: Entrypoint Configuration
#* Version: Entrypoint-V0.1-beta
#* Date: 2023-06-19
#* By: KingMaj0r
# *
# * *****************************************************************************
#**/

#!/bin/bash

#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
ORANGE='\033[0;91m'
NC='\033[0m' # No Color

# Function to print a bordered line with larger text
print_bordered_line() {
    local text="$1"
    local text_length=${#text}
    local border_length=70

    local border_line=""
    for i in $(seq 1 $border_length); do
        border_line="${border_line}─"
    done

    local padding_length=$(( (border_length - text_length - 2) / 2 ))
    local padding=""
    for i in $(seq 1 $padding_length); do
        padding="${padding} "
    done

    printf "${GREEN}\e[1m┌%s┐${NC}\n" "$border_line"
    printf "${GREEN}\e[1m│${NC}%s%s%s   ${GREEN}\e[1m│${NC}\n" "$padding" "$text" "$padding"
    printf "${GREEN}\e[1m└%s┘${NC}\n" "$border_line"
}

mkdir /etc/lemp
mkdir /run/php-fpm

chmod -R 777 /var/www/lemp

cd /var/www/lemp

if [ ! -f /etc/lemp/installed ]; then
    if [ "$PHPMYADMIN" = true ]; then
        # Install phpMyAdmin
        apk add phpmyadmin >/dev/null 2>&1 &

        mkdir /etc/phpmyadmin
        chown -R nginx:nginx /etc/phpmyadmin

        # Copy Nginx configuration file
        cp /etc/nginx/phpmyadmin.conf /etc/nginx/http.d/phpmyadmin.conf

        mkdir /var/lib/php
        mkdir /var/lib/php/session
        chmod 777 /var/lib/php/session
    else
        echo "phpMyAdmin installation skipped."
    fi
fi

# Start some important services.
start_services() {
    redis-server --daemonize yes &
    if [ -f /etc/lemp/installed ]; then
        mysqld --user=mysql --skip-networking >/dev/null 2>&1 &
    fi
    php-fpm82 --nodaemonize &
    nginx -g 'daemon off;' &
}
start_services

if [ ! -f /etc/lemp/installed ]; then
    # Generate SSL Certificate
    if [ "$SSL_ENABLED" = true ]; then
        /usr/local/bin/generate-cert.sh
    fi

    # Replace Placeholders in Nginx Configuration File
    if [ "$SSL_ENABLED" = true ]; then
        rm /etc/nginx/http.d/default.conf
        mv /etc/nginx/lemp.conf /etc/nginx/http.d
        mv /etc/nginx/ssl-server-block.conf /etc/nginx/http.d
    else
        rm /etc/nginx/http.d/default.conf
        mv /etc/nginx/lemp.conf /etc/nginx/http.d
    fi

    setup_mysql() {
        mysql_install_db --user=mysql --ldata=/var/lib/mysql/ >/dev/null 2>&1
        mkdir -p /run/mysqld/
        chown mysql:mysql /run/mysqld/
        chown -R mysql:mysql /var/lib/mysql/
        chmod -R 755 /var/lib/mysql/
        rm -rf /var/lib/mysql/ibdata1 /var/lib/mysql/ib_logfile*
        mysqld --user=mysql --skip-networking >/dev/null 2>&1 &
        sleep 5
        mysql -u root --password=$MYSQL_ROOT_PASSWORD --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
        mysql -u root --password=$MYSQL_ROOT_PASSWORD --execute="FLUSH PRIVILEGES;" >/dev/null 2>&1
        mysql -u root --password=$MYSQL_ROOT_PASSWORD --execute="CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;"
        mysql -u root --password=$MYSQL_ROOT_PASSWORD --execute="GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
        mysql -u root --password=$MYSQL_ROOT_PASSWORD --execute="FLUSH PRIVILEGES;" >/deinitial_setup_completed
    }
    setup_mysql
    redis-cli config set requirepass "$REDIS_PASSWORD" >/dev/null 2>&1
    touch /etc/lemp/installed
    echo "If you intend to reinstall the server, kindly delete this file." > /etc/lemp/installed
fi

# Display server started message and the link
print_bordered_line "LEMP has started! - Developed by KingMaj0r."
if [ -f /etc/lemp/credentials_shown ]; then
    echo
    echo -e "${CYAN}★${NC} Website: http://$SERVER_NAME${NC}"
fi
# Check if the flag file exists
if [ ! -f /etc/lemp/credentials_shown ]; then

    # Display MySQL and Redis details
    echo
    echo -e "${CYAN}★${NC} Website: http://$SERVER_NAME${NC}"
    echo
    echo -e "${YELLOW}MySQL Details:${NC}"
    echo -e "${CYAN}❶${NC}  Host: ${CYAN}127.0.0.1${NC}" # Temporary
    echo -e "${CYAN}❷${NC}  Port: ${CYAN}3306${NC}" # Temporary
    echo -e "${CYAN}❸${NC}  User: ${CYAN}$MYSQL_USER${NC}"
    echo -e "${CYAN}❹${NC}  Password: ${CYAN}$MYSQL_PASSWORD${NC}"
    echo -e "${CYAN}❺${NC}  root Password: ${CYAN}$MYSQL_ROOT_PASSWORD${NC}"
    echo
    echo -e "${YELLOW}Redis Details:${NC}"
    echo -e "${CYAN}❶${NC}  Host: ${CYAN}127.0.0.1${NC}"
    echo -e "${CYAN}❷${NC}  Port: ${CYAN}6379${NC}"
    echo -e "${CYAN}❸${NC}  Password: ${CYAN}$REDIS_PASSWORD${NC}"

    # Create the flag file to indicate that the credentials have been shown
    touch /etc/lemp/credentials_shown
    echo "If you wish to display the credentials again, please delete this file." > /etc/lemp/credentials_shown
fi

exec "$@"
wait