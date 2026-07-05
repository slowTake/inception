#!/bin/sh
set -e

DOMAIN="${DOMAIN_NAME:-login.42.fr}"

openssl req -x509 -nodes -days 365 \
	-out /etc/nginx/ssl/public_certificate.crt \
	-keyout /etc/nginx/ssl/private.key \
	-subj "/C=FI/ST=Uusimaa/L=Helsinki/O=42/OU=Hive/CN=${DOMAIN}"

sed "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
