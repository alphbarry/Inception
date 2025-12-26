FROM alpine:3.19

RUN apk update && apk add --no-cache \
    nginx \
    openssl

# Create www-data user/group to match WordPress container
RUN addgroup -g 82 -S www-data 2>/dev/null || true \
 && adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true

RUN mkdir -p /run/nginx /var/log/nginx \
 && chown -R www-data:www-data /run/nginx /var/log/nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/generate_ssl.sh /usr/local/bin/generate_ssl.sh
RUN chmod +x /usr/local/bin/generate_ssl.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/generate_ssl.sh"]

