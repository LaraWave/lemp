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

source <(curl -sSL "https://raw.githubusercontent.com/kingmaj0r/TerminalStyle/main/colors.sh")

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
    mkdir /etc/lemp
    mkdir /run/php-fpm

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

    if [ "$PHPMYADMIN" = true ]; then
        # Remove the existing phpmyadmin directory if it exists
        if [ -d /var/www/html/phpmyadmin ]; then
            rm -rf /var/www/html/phpmyadmin
        fi

        # Get the URL of the latest release of phpMyAdmin
        TAG_NAME=$(git ls-remote --tags https://github.com/phpmyadmin/phpmyadmin.git | awk '{print $2}' | grep -v '{}' | grep -v '\^{}' | awk -F/ '{print $3}' | sort -rV | head -n1)
        
        # Clone the phpMyAdmin repository into /var/www/html/phpmyadmin and switch to the latest release tag
        if git clone --depth=1 --branch="$TAG_NAME" https://github.com/phpmyadmin/phpmyadmin.git /var/www/html/phpmyadmin >/dev/null 2>&1 && cd /var/www/html/phpmyadmin; then
            # Update dependencies using composer
            composer update --no-dev >/dev/null 2>&1
            
            # Rename the configuration file and create a new one
            if [ -f config.sample.inc.php ]; then
                mv config.sample.inc.php config.inc.php
                cp config.inc.php config.inc.php.sample
                
                # Generate a secret passphrase for the new configuration file
                SECRET=$(openssl rand -base64 32)
                sed -i "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$SECRET'|g" config.inc.php
            fi
            
            # Set the correct permissions on the directory
            chmod -R 755 -R .
            chown -R nginx:nginx .
            if [ ! -d ./tmp ]; then
                mkdir ./tmp
            fi
            chmod 777 ./tmp
            
            cd ..
        else
            echo "Failed to clone phpMyAdmin repository or switch to the latest release tag." >&2
            exit 1
        fi
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