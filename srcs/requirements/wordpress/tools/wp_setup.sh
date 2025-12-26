#!/bin/sh

mkdir -p /var/www/html
cd /var/www/html

# Verificar que PHP-FPM esté configurado correctamente
if ! grep -q "listen = 0.0.0.0:9000" /etc/php82/php-fpm.d/www.conf; then
  sed -i 's|listen = .*|listen = 0.0.0.0:9000|' /etc/php82/php-fpm.d/www.conf
fi

# Instalar WP-CLI si no está disponible
if ! command -v wp >/dev/null 2>&1; then
  curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

# Raise WP-CLI memory to avoid OOM on download/extract
export WP_CLI_PHP_ARGS="-d memory_limit=256M"

# Poblar WordPress incluso si el volumen está vacío antes de que arranque MariaDB
if [ ! -f index.php ]; then
  echo "Descargando WordPress..."
  wp core download --allow-root --force || true
fi

# Esperar a MariaDB antes de configurar wp-config e instalar
echo "Esperando a MariaDB..."
DB_PASSWORD=$(cat /run/secrets/db_password 2>/dev/null || echo "")
MAX_RETRIES=30
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
  if mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$DB_PASSWORD" --silent 2>/dev/null; then
    echo "MariaDB está disponible"
    break
  fi
  echo "Intento $((RETRY + 1))/$MAX_RETRIES: Esperando a MariaDB..."
  sleep 2
  RETRY=$((RETRY + 1))
done

# Crear wp-config si no existe
if [ ! -f wp-config.php ]; then
  if [ -f wp-config-sample.php ]; then
    echo "Creando wp-config.php..."
    cp wp-config-sample.php wp-config.php

    sed -i "s/database_name_here/$MYSQL_DATABASE/" wp-config.php
    sed -i "s/username_here/$MYSQL_USER/" wp-config.php
    sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
    sed -i "s/localhost/mariadb/" wp-config.php

    echo "Instalando WordPress..."
    wp core install \
      --url=https://$DOMAIN_NAME \
      --title="$WP_TITLE" \
      --admin_user="$WP_ADMIN_USER" \
      --admin_password="$DB_PASSWORD" \
      --admin_email="$WP_ADMIN_EMAIL" \
      --skip-email \
      --allow-root 2>&1 || echo "Error en wp core install, continuando..."

    echo "Creando usuario adicional..."
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
      --role=editor \
      --user_pass="$DB_PASSWORD" \
      --allow-root 2>&1 || echo "Usuario ya existe o error, continuando..."
  else
    echo "ERROR: wp-config-sample.php no encontrado"
  fi
else
  echo "wp-config.php ya existe, saltando configuración"
fi

chown -R www-data:www-data /var/www/html

# Iniciar PHP-FPM
echo "Iniciando PHP-FPM..."
php-fpm82 -t && echo "Configuración de PHP-FPM válida"

# Mantener PHP-FPM corriendo en primer plano
exec php-fpm82 -F

