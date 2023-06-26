#/**
# * *****************************************************************************
# *                        All Rights Reserved
# *
#* Title: Dockerfile Configuration
#* Version: Dockerfile-V0.1-beta
#* Date: 2023-06-16
#* By: KingMaj0r
# *
# * *****************************************************************************
#**/

# Import the image
FROM alpine:3.16

# Proxy example (not needed unless your using a proxy.)
#ENV HTTP_PROXY http://IP:Port
#ENV HTTPS_PROXY http://IP:Port

# Enable edge and edge community repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Install PHP 8.1 and necessary extensions
RUN apk update &&           \
    apk add --no-cache      \
    curl                    \
    nginx                   \
    redis                   \
    mariadb                 \
    mariadb-client          \
    openssl                 \
    gettext                 \
    php81                   \
    php81-fpm               \
    php81-mysqli            \
    php81-json              \
    php81-curl              \
    php81-xml               \
    php81-phar              \
    php81-intl              \
    php81-xmlreader         \
    php81-tokenizer         \
    php81-fileinfo          \
    php81-simplexml         \
    php81-xmlwriter         \
    php81-mbstring          \
    php81-pdo_mysql         \
    php81-zlib              \
    php81-dom               \
    php81-ctype             \
    php81-session           \
    php81-iconv             \
    php81-zip               \
    php81-opcache

# Copy SSL Certificate Generation Script
COPY ./scripts/generate-cert.sh /usr/local/bin/generate-cert.sh
COPY ./scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/generate-cert.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set up MySQL
RUN mkdir /run/mysqld && \
    chown mysql:mysql /run/mysqld && \
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# Copy configuration files
COPY ./config/nginx/nginx.conf.template /etc/nginx/nginx.conf.template
COPY ./config/php-fpm/www.conf /etc/php81/php-fpm.d/www.conf
COPY ./config/mariadb/my.cnf /etc/my.cnf.
COPY ./config/nginx/ssl-server-block.conf /etc/nginx/ssl-server-block.conf

# Generate SSL Certificate
RUN if [ "$SSL_ENABLED" = true ]; then /usr/local/bin/generate-cert.sh; fi

# Set up volumes
VOLUME /var/www/html
VOLUME /var/lib/mysql
VOLUME /var/log/nginx
VOLUME /var/log/php-fpm

# Set environment variables
ENV TERM xterm-256color
ENV MYSQL_ROOT_PASSWORD=password
ENV MYSQL_DATABASE=default
ENV MYSQL_USER=default_user
ENV MYSQL_PASSWORD=password

# Expose the necessary ports
EXPOSE 80
EXPOSE 443
EXPOSE 3306
EXPOSE 6379
EXPOSE 9000

ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
