# Developer Documentation

This document describes how to set up, build, and develop the Inception project from scratch.

## Prerequisites

### Required Software

- **Docker Engine**: Version 20.10 or higher
  - Installation: See [INSTALL_DOCKER.md](INSTALL_DOCUMENT.md) or [Docker Installation Guide](https://docs.docker.com/engine/install/)
- **Docker Compose**: Version 2.0+ (recommended) or 1.29+
  - Usually included with Docker Desktop
  - Can be installed separately: `sudo apt-get install docker-compose-plugin`
- **Git**: For version control
- **Text Editor**: For editing configuration files (vim, nano, VS Code, etc.)

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+ recommended), macOS, or Windows with WSL2
- **RAM**: Minimum 2GB (4GB+ recommended)
- **Disk Space**: At least 5GB free space
- **Network**: Internet connection for downloading images and WordPress

### Knowledge Prerequisites

- Basic Linux command line skills
- Understanding of Docker basics (images, containers, volumes, networks)
- Familiarity with YAML syntax (for docker-compose.yml)
- Basic understanding of web servers (Nginx) and databases (MySQL/MariaDB)

## Environment Setup from Scratch

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Inception
```

### 2. Create Environment Configuration

Create a `.env` file in the `srcs/` directory:

```bash
cd srcs
cat > .env << EOF
DOMAIN_NAME=alphbarr.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_TITLE=Inception WordPress Site
WP_ADMIN_USER=admin
WP_ADMIN_EMAIL=admin@alphbarr.42.fr
WP_USER=editor
WP_USER_EMAIL=editor@alphbarr.42.fr
EOF
```

**Environment Variables Explained:**

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN_NAME` | Domain name for the website | `alphbarr.42.fr` |
| `MYSQL_DATABASE` | Database name for WordPress | `wordpress` |
| `MYSQL_USER` | Database user for WordPress | `wpuser` |
| `WP_TITLE` | WordPress site title | `My Site` |
| `WP_ADMIN_USER` | WordPress administrator username | `admin` |
| `WP_ADMIN_EMAIL` | WordPress administrator email | `admin@example.com` |
| `WP_USER` | Additional WordPress user (editor role) | `editor` |
| `WP_USER_EMAIL` | Additional user email | `editor@example.com` |

### 3. Create Secrets

Create the `secrets` directory and password files:

```bash
# From project root
mkdir -p secrets

# Generate secure passwords
echo "your_secure_root_password_here" > secrets/db_root_password.txt
echo "your_secure_user_password_here" > secrets/db_password.txt

# Set secure permissions (recommended)
chmod 600 secrets/*.txt
```

**Security Notes:**
- Use strong, unique passwords (minimum 16 characters)
- Never commit these files to Git (ensure they're in `.gitignore`)
- Use `chmod 600` to restrict access to owner only

### 4. Configure /etc/hosts (Local Development)

For local testing, add the domain to your hosts file:

```bash
sudo bash -c 'echo "127.0.0.1 alphbarr.42.fr" >> /etc/hosts'
```

### 5. Verify Docker Installation

```bash
docker --version
docker compose version
```

## Building and Launching the Project

### Using Docker Compose

#### Build All Images

```bash
cd srcs
docker compose build
```

This builds all three container images:
- `inception-nginx` (based on `requirements/nginx/Dockerfile`)
- `inception-wordpress` (based on `requirements/wordpress/Dockerfile`)
- `inception-mariadb` (based on `requirements/mariadb/Dockerfile`)

#### Build Specific Service

```bash
# Build only Nginx
docker compose build nginx

# Build only WordPress
docker compose build wordpress

# Build only MariaDB
docker compose build mariadb
```

#### Build with No Cache

To force a fresh build (useful when Dockerfiles change):

```bash
docker compose build --no-cache
```

### Launch the Project

#### Start All Services

```bash
cd srcs
docker compose up -d
```

The `-d` flag runs containers in detached mode (background).

**What happens:**
1. Docker Compose reads `docker-compose.yml`
2. Creates the `inception` bridge network
3. Creates volumes: `mariadb_data` and `wordpress_data`
4. Starts containers in dependency order:
   - MariaDB starts first
   - WordPress waits for MariaDB to be ready
   - Nginx waits for WordPress to be ready

#### Start Specific Service

```bash
docker compose up -d nginx
```

Note: This will also start dependencies (mariadb, wordpress) if not running.

#### View Build/Start Logs

```bash
# Show logs during startup (without -d flag)
docker compose up

# Follow logs after starting
docker compose logs -f
```

### Using Makefile (Optional)

If a Makefile is provided, you can use these commands:

```bash
# Build all images
make build

# Start services
make up

# Stop services
make down

# View logs
make logs

# Rebuild everything
make re
```

See the Makefile section below for available targets.

## Container and Volume Management

### Container Commands

#### List Running Containers

```bash
docker compose ps
```

#### View Container Details

```bash
# Detailed information about a container
docker inspect <container_name>

# Example
docker inspect nginx
```

#### Execute Commands in Containers

```bash
# Execute command in container
docker compose exec <service_name> <command>

# Examples
docker compose exec wordpress ls -la /var/www/html
docker compose exec mariadb mysql -u root -p
docker compose exec nginx nginx -t  # Test Nginx configuration
```

#### Access Container Shell

```bash
# Access interactive shell
docker compose exec <service_name> /bin/sh

# Examples
docker compose exec wordpress /bin/sh
docker compose exec mariadb /bin/sh
docker compose exec nginx /bin/sh
```

#### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart nginx
docker compose restart wordpress
docker compose restart mariadb
```

#### Stop Services

```bash
# Stop all services (containers remain)
docker compose stop

# Stop specific service
docker compose stop nginx
```

#### Remove Containers

```bash
# Stop and remove containers (volumes preserved)
docker compose down

# Stop and remove containers + volumes (⚠️ deletes data)
docker compose down -v
```

### Volume Management

#### List Volumes

```bash
# List all volumes
docker volume ls

# List project volumes
docker compose config --volumes
```

#### Inspect Volume

```bash
# View volume details (location, mountpoint)
docker volume inspect inception_wordpress_data
docker volume inspect inception_mariadb_data
```

#### Backup Volume Data

```bash
# Backup WordPress data
docker run --rm -v inception_wordpress_data:/data -v $(pwd):/backup alpine tar czf /backup/wordpress_backup.tar.gz -C /data .

# Backup MariaDB data
docker run --rm -v inception_mariadb_data:/data -v $(pwd):/backup alpine tar czf /backup/mariadb_backup.tar.gz -C /data .
```

#### Restore Volume Data

```bash
# Restore WordPress data
docker run --rm -v inception_wordpress_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/wordpress_backup.tar.gz"

# Restore MariaDB data
docker run --rm -v inception_mariadb_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/mariadb_backup.tar.gz"
```

#### Remove Volumes

⚠️ **Warning**: This permanently deletes data!

```bash
# Remove specific volume
docker volume rm inception_wordpress_data

# Remove all unused volumes
docker volume prune
```

### Network Management

#### List Networks

```bash
docker network ls
```

#### Inspect Network

```bash
# View network details
docker network inspect inception_inception
```

#### Test Network Connectivity

```bash
# Test connection from WordPress to MariaDB
docker compose exec wordpress ping -c 3 mariadb

# Test connection from Nginx to WordPress
docker compose exec nginx ping -c 3 wordpress
```

## Project Data Storage and Persistence

### Where Data is Stored

#### Database Data (MariaDB)

- **Volume Name**: `inception_mariadb_data` (or `mariadb_data` in compose)
- **Container Path**: `/var/lib/mysql`
- **Host Path**: Managed by Docker (typically `/var/lib/docker/volumes/inception_mariadb_data/_data`)

**Contains:**
- Database files (`.ibd`, `.frm` files)
- MySQL system tables
- WordPress database tables (wp_posts, wp_users, wp_options, etc.)
- Transaction logs

#### WordPress Data

- **Volume Name**: `inception_wordpress_data` (or `wordpress_data` in compose)
- **Container Path**: `/var/www/html`
- **Host Path**: Managed by Docker (typically `/var/lib/docker/volumes/inception_wordpress_data/_data`)

**Contains:**
- WordPress core files (`wp-admin/`, `wp-includes/`, `wp-content/`)
- WordPress configuration (`wp-config.php`)
- Themes (`wp-content/themes/`)
- Plugins (`wp-content/plugins/`)
- Uploaded media (`wp-content/uploads/`)
- Custom code and configurations

### How Data Persists

#### Volume Persistence

Data persists because:
1. **Named Docker Volumes**: Volumes are created with names and managed by Docker
2. **Independent Lifecycle**: Volumes exist independently of containers
3. **Volume Mounting**: Containers mount volumes, but volumes persist after container removal

#### Data Persistence Scenarios

**Scenario 1: Container Restart**
```bash
docker compose restart wordpress
```
✅ **Data preserved**: Volumes remain mounted, data intact

**Scenario 2: Container Rebuild**
```bash
docker compose stop
docker compose build wordpress
docker compose up -d
```
✅ **Data preserved**: Volumes remain, containers remount existing volumes

**Scenario 3: Container Removal (without -v)**
```bash
docker compose down
docker compose up -d
```
✅ **Data preserved**: Containers removed, volumes remain, new containers mount existing volumes

**Scenario 4: Container Removal (with -v)**
```bash
docker compose down -v
docker compose up -d
```
❌ **Data deleted**: Volumes removed, fresh volumes created, all data lost

### Accessing Data Directly

#### View WordPress Files

```bash
# List WordPress files
docker compose exec wordpress ls -la /var/www/html

# View wp-config.php
docker compose exec wordpress cat /var/www/html/wp-config.php

# Access WordPress directory
docker compose exec wordpress /bin/sh
cd /var/www/html
```

#### Access Database

```bash
# Connect to MariaDB
docker compose exec mariadb mysql -u root -p$(cat /run/secrets/db_root_password)

# Or interactively
docker compose exec -it mariadb mysql -u root -p
# Enter password from secrets/db_root_password.txt

# List databases
mysql> SHOW DATABASES;

# Use WordPress database
mysql> USE wordpress;

# List tables
mysql> SHOW TABLES;

# Query data
mysql> SELECT * FROM wp_users;
```

#### Backup Data

**Full Backup Script:**
```bash
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup WordPress
docker run --rm \
  -v inception_wordpress_data:/data \
  -v $(pwd)/$BACKUP_DIR:/backup \
  alpine tar czf /backup/wordpress_$DATE.tar.gz -C /data .

# Backup MariaDB
docker run --rm \
  -v inception_mariadb_data:/data \
  -v $(pwd)/$BACKUP_DIR:/backup \
  alpine tar czf /backup/mariadb_$DATE.tar.gz -C /data .

echo "Backup completed: $BACKUP_DIR"
```

### Data Migration

#### Move to New Server

1. **Export data on source server:**
   ```bash
   docker compose exec mariadb mysqldump -u root -p wordpress > wordpress.sql
   # Copy volumes or use backup script above
   ```

2. **Import data on destination server:**
   ```bash
   # Copy volumes or restore backups
   docker compose exec -i mariadb mysql -u root -p wordpress < wordpress.sql
   ```

## Development Workflow

### Making Changes to Dockerfiles

1. **Edit Dockerfile:**
   ```bash
   vim srcs/requirements/nginx/Dockerfile
   ```

2. **Rebuild the image:**
   ```bash
   docker compose build nginx
   ```

3. **Restart the service:**
   ```bash
   docker compose up -d nginx
   ```

### Making Changes to Configuration Files

1. **Edit configuration:**
   ```bash
   vim srcs/requirements/nginx/conf/nginx.conf
   ```

2. **Rebuild (if Dockerfile copies config):**
   ```bash
   docker compose build nginx
   docker compose up -d nginx
   ```

3. **Or restart (if config is in volume):**
   ```bash
   docker compose restart nginx
   ```

### Testing Changes

```bash
# Test Nginx configuration
docker compose exec nginx nginx -t

# Check container logs
docker compose logs -f nginx

# Test website
curl -k https://alphbarr.42.fr
```

### Debugging

#### View Logs

```bash
# All logs
docker compose logs

# Specific service
docker compose logs wordpress

# Follow logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100
```

#### Inspect Container State

```bash
# Container processes
docker compose exec wordpress ps aux

# Container environment
docker compose exec wordpress env

# Network connectivity
docker compose exec wordpress ping mariadb
```

## Troubleshooting

### Common Issues

#### Port Already in Use

**Error**: `Bind for 0.0.0.0:443 failed: port is already allocated`

**Solution**:
```bash
# Find process using port 443
sudo lsof -i :443
# Kill the process or change port in docker-compose.yml
```

#### Permission Denied Errors

**Error**: `Permission denied` when accessing files

**Solution**:
```bash
# Check file permissions in container
docker compose exec wordpress ls -la /var/www/html

# Fix permissions (if needed)
docker compose exec wordpress chown -R www-data:www-data /var/www/html
```

#### Database Connection Failed

**Error**: WordPress can't connect to database

**Solution**:
```bash
# Check if MariaDB is running
docker compose ps mariadb

# Test database connection
docker compose exec wordpress mysqladmin ping -h mariadb -u wpuser -p

# Check database credentials
docker compose exec wordpress cat /var/www/html/wp-config.php | grep DB_
```

#### Out of Disk Space

**Error**: `no space left on device`

**Solution**:
```bash
# Check disk usage
df -h

# Clean Docker system
docker system prune -a

# Remove unused volumes
docker volume prune
```

## Project Structure

```
Inception/
├── README.md              # Main project documentation
├── USER_DOC.md           # User documentation
├── DEV_DOC.md            # This file
├── Makefile              # Build automation (if provided)
├── secrets/              # Password files (⚠️ not in Git)
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml # Orchestration file
    ├── .env              # Environment variables (⚠️ not in Git)
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       └── init_db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── generate_ssl.sh
        └── wordpress/
            ├── Dockerfile
            └── tools/
                └── wp_setup.sh
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [WordPress Development](https://developer.wordpress.org/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)

