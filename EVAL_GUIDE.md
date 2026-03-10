# Guía rápida para la defensa en la VM de 42

1. **Preparar directorios requeridos**
   ```bash
   mkdir -p /home/<login>/data/mariadb /home/<login>/data/wordpress
   ```
   Sustituye `<login>` por tu usuario 42 o usa `make HOST_LOGIN=<login> ...`.

2. **Cargar el proyecto**
   ```bash
   git clone <repo-url>
   cd Inception
   make HOST_LOGIN=<login> up
   ```

3. **Comprobaciones obligatorias**
   - `docker compose ps` → servicios `mariadb`, `wordpress`, `nginx` en estado *Up*.
   - `docker volume inspect inception_wordpress_data` / `inception_mariadb_data` → `Mountpoint` en `/home/<login>/data/...`.
   - Accede sólo por HTTPS: `https://<login>.42.fr` (añade a `/etc/hosts` si es local). HTTP debe fallar.
   - Inicia sesión como `supervisor` (contraseña = `secrets/db_password.txt`), crea/edita contenido y deja un comentario con `editor`.
   - `docker compose exec mariadb mysql -u root -p$(cat ../secrets/db_root_password.txt)` → muestra que la DB no está vacía.

4. **Persistencia**
   - `sudo reboot`
   - `make up`
   - Verifica que el contenido modificado sigue presente.

5. **Modificación pedida**
   - Cambia un ajuste (p.ej. expone Nginx en otro puerto), `make down`, edita, luego `make build` + `make up`.
   - Demuestra que todo sigue operativo tras el cambio.

6. **Comandos útiles**
   - `make logs`, `make exec-nginx`, `make exec-wordpress`, `make exec-mariadb`
   - `openssl s_client -connect <login>.42.fr:443 -tls1_2`
   - `docker network ls`, `docker volume ls`

Esta guía resume los pasos exigidos por la hoja de evaluación y sirve como checklist antes de la defensa.
