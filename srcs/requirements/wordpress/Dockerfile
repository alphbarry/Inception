FROM alpine:3.19

RUN apk update && apk add --no-cache \
    php82 \
    php82-fpm \
    php82-mysqli \
    php82-phar \
    php82-json \
    php82-curl \
    php82-dom \
    php82-mbstring \
    php82-openssl \
    php82-zip \
    php82-session \
    curl \
    mariadb-client

RUN mkdir -p /run/php
RUN mkdir -p /var/www/html

COPY tools/wp_setup.sh /usr/local/bin/wp_setup.sh
RUN chmod +x /usr/local/bin/wp_setup.sh

EXPOSE 9000

RUN sed -i 's|^user = .*|user = www-data|' /etc/php82/php-fpm.d/www.conf \
 && sed -i 's|^group = .*|group = www-data|' /etc/php82/php-fpm.d/www.conf \
 && sed -i 's|listen = .*|listen = 9000|' /etc/php82/php-fpm.d/www.conf \
 && sed -i 's|;clear_env = no|clear_env = no|' /etc/php82/php-fpm.d/www.conf

RUN grep -q '^www-data:' /etc/group || addgroup -S www-data \
 && grep -q '^www-data:' /etc/passwd || adduser -S -G www-data www-data \
 && chown -R www-data:www-data /var/www/html /run/php


ENTRYPOINT ["/usr/local/bin/wp_setup.sh"]
