FROM alpine:3.20.6

RUN apk update && apk add --no-cache nginx openssl

EXPOSE 443

RUN mkdir -p /etc/nginx/ssl \
	&& adduser -D -H -s /sbin/nologin -g www-data -G www-data www-data

COPY ./conf/nginx.conf /etc/nginx/nginx.conf.template
COPY ./tools/nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint.sh
RUN chmod +x /usr/local/bin/nginx-entrypoint.sh

CMD ["/usr/local/bin/nginx-entrypoint.sh"]
