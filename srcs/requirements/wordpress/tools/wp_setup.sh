#!/bin/sh
set -e

cd /var/www/html

# Esperar a MariaDB
until mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$(cat /run/secrets/db_password)" --silent; do
  sleep 2
done

# Descargar WP solo si no existe
if [ ! -f wp-config.php ]; then
  curl -O https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz --strip-components=1
  rm latest.tar.gz

  cp wp-config-sample.php wp-config.php

  sed -i "s/database_name_here/$MYSQL_DATABASE/" wp-config.php
  sed -i "s/username_here/$MYSQL_USER/" wp-config.php
  sed -i "s/password_here/$(cat /run/secrets/db_password)/" wp-config.php
  sed -i "s/localhost/mariadb/" wp-config.php

  wp core install \
    --url=https://$DOMAIN_NAME \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$(cat /run/secrets/db_password)" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email

  wp user create "$WP_USER" "$WP_USER_EMAIL" \
    --role=editor \
    --user_pass="$(cat /run/secrets/db_password)"
fi

exec php-fpm82 -F

