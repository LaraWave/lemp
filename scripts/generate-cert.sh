#!/bin/bash

# Generate SSL Certificate
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
  -out /etc/nginx/ssl/nginx-selfsigned.crt \
  -keyout /etc/nginx/ssl/nginx-selfsigned.key \
  -subj "/C=US/ST=CA/L=San Francisco/O=Example Company/CN=${SERVER_NAME}"

# Set Permissions
chmod 600 /etc/nginx/ssl/nginx-selfsigned.*

# Verify Certificate
openssl x509 -noout -text -in /etc/nginx/ssl/nginx-selfsigned.crt