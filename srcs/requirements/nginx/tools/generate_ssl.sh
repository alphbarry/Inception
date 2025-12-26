#!/bin/sh
set -e

CERT_DIR=/etc/nginx/ssl
mkdir -p $CERT_DIR

if [ ! -f "$CERT_DIR/server.crt" ]; then
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout $CERT_DIR/server.key \
    -out $CERT_DIR/server.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=$DOMAIN_NAME"
fi

# Asegurar permisos correctos en el directorio web
if [ -d /var/www/html ]; then
  chown -R www-data:www-data /var/www/html
  chmod -R 755 /var/www/html
fi

# Esperar a que PHP-FPM esté listo
echo "Esperando a que PHP-FPM esté disponible..."
until nc -z wordpress 9000 2>/dev/null; do
  echo "Esperando conexión a wordpress:9000..."
  sleep 2
done
echo "PHP-FPM está disponible"

# Verificar configuración de nginx
nginx -t

exec nginx -g "daemon off;"

