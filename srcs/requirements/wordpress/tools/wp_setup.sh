#!/bin/sh
set -euo pipefail

mkdir -p /var/www/html
cd /var/www/html

# Instalar WP-CLI si no está disponible
if ! command -v wp >/dev/null 2>&1; then
  curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# Raise WP-CLI memory to avoid OOM on download/extract
export WP_CLI_PHP_ARGS="-d memory_limit=256M"

# Poblar WordPress incluso si el volumen está vacío antes de que arranque MariaDB
if [ ! -f index.php ]; then
  wp core download --allow-root --force
fi

# Instalar WP-CLI si no está disponible
if ! command -v wp >/dev/null 2>&1; then
  curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# Esperar a MariaDB antes de configurar wp-config e instalar
until mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$(cat /run/secrets/db_password)" --silent; do
  sleep 2
done

# Crear wp-config si no existe
if [ ! -f wp-config.php ]; then
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
    --skip-email \
    --allow-root

  wp user create "$WP_USER" "$WP_USER_EMAIL" \
    --role=editor \
    --user_pass="$(cat /run/secrets/db_password)" \
    --allow-root
fi

chown -R www-data:www-data /var/www/html

exec php-fpm82 -F

