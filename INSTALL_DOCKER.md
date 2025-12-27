# Instalación de Docker en Ubuntu 24.04

## Pasos para instalar Docker

### 1. Actualizar el sistema
```bash
sudo apt-get update
```

### 2. Instalar dependencias necesarias
```bash
sudo apt-get install -y ca-certificates curl
```

### 3. Crear directorio para claves GPG de Docker
```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

### 4. Descargar y agregar la clave GPG oficial de Docker
```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### 5. Configurar el repositorio de Docker
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 6. Actualizar los paquetes
```bash
sudo apt-get update
```

### 7. Instalar Docker Engine, containerd y Docker Compose
```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 8. Verificar que Docker esté instalado correctamente
```bash
sudo docker --version
docker compose version
```

### 9. Agregar tu usuario al grupo docker (para no usar sudo)
```bash
sudo usermod -aG docker $USER
```

### 10. Reiniciar la sesión o aplicar los cambios del grupo
```bash
newgrp docker
```

### 11. Verificar que Docker funciona sin sudo
```bash
docker run hello-world
```

## Instalación rápida (todo en uno)

Si prefieres, puedes ejecutar todos los comandos de una vez:

```bash
sudo apt-get update && \
sudo apt-get install -y ca-certificates curl && \
sudo install -m 0755 -d /etc/apt/keyrings && \
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
sudo chmod a+r /etc/apt/keyrings/docker.asc && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
sudo apt-get update && \
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
sudo usermod -aG docker $USER && \
newgrp docker
```

## Notas importantes

- Después de agregar tu usuario al grupo `docker`, necesitas cerrar y abrir una nueva terminal o ejecutar `newgrp docker` para que los cambios surtan efecto.

- Docker Compose v2 viene incluido como plugin (`docker compose`), que es el recomendado.

- Si prefieres usar `docker-compose` (v1), puedes instalarlo por separado, pero es mejor usar el plugin incluido.

## Solución de problemas

Si tienes problemas con permisos después de la instalación:
```bash
# Verificar que estás en el grupo docker
groups

# Si no aparece docker, agregar de nuevo y reiniciar sesión
sudo usermod -aG docker $USER
# Luego cerrar y abrir terminal
```

