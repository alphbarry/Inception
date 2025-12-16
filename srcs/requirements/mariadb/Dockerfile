FROM alpine:3.19

RUN apk update && apk add --na-cache \
	mariadb \
	mariadb-client

RUN mkdir -p /var/lib/mysql /run/mysql \
 && chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["*/usr/local/bin/init_db.sh"]
