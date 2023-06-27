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
ENV http_proxy=http://172.16.254.1:3128
ENV https_proxy=http://172.16.254.1:3128
ENV HTTP_PROXY=http://172.16.254.1:3128
ENV HTTPS_PROXY=http://172.16.254.1:3128

# Enable edge and edge community repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Install important dependinces
RUN apk update &&           \
    apk add --no-cache      \
    curl                    \
    nginx                   \
    redis                   \
    mariadb                 \
    mariadb-client          \
    openssl                 \
    gettext                 \
    php82                   \
    php82-fpm               \
    php82-mysqli            \
    php82-json              \
    php82-curl              \
    php82-xml               \
    php82-phar              \
    php82-intl              \
    php82-xmlreader         \
    php82-tokenizer         \
    php82-fileinfo          \
    php82-simplexml         \
    php82-xmlwriter         \
    php82-mbstring          \
    php82-pdo_mysql         \
    php82-zlib              \
    php82-dom               \
    php82-ctype             \
    php82-session           \
    php82-iconv             \
    php82-zip               \
    php82-opcache &&        \
    rm -rf /var/lib/apt/lists/*

# Copy SSL Certificate Generation Script
COPY ./scripts/generate-cert.sh /usr/local/bin/generate-cert.sh
COPY ./scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/generate-cert.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy configuration files
COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx/lemp.conf /etc/nginx/lemp.conf
COPY ./config/nginx/phpmyadmin.conf /etc/nginx/phpmyadmin.conf
COPY ./config/nginx/ssl-server-block.conf /etc/nginx/ssl-server-block.conf
COPY ./config/php-fpm/www.conf /etc/php82/php-fpm.d/www.conf
COPY ./config/mariadb/my.cnf /etc/my.cnf

# Generate SSL Certificate
RUN if [ "$SSL_ENABLED" = true ]; then /usr/local/bin/generate-cert.sh; fi

# Set up volumes
VOLUME /var/www/html
VOLUME /var/lib/mysql
VOLUME /var/log/nginx
VOLUME /var/log/php-fpm

# Set environment variables
ENV TERM xterm-256color

# Expose the necessary ports
EXPOSE 80
EXPOSE 443
EXPOSE 3306
EXPOSE 6379
EXPOSE 9000

ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
