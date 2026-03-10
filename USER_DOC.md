# User Documentation

This document explains how to use the Inception project as an end user or administrator.

## Services Provided by the Stack

The Inception project deploys three main services working together:

### 1. **Nginx** (Web Server & Reverse Proxy)
- **Container name**: `nginx`
- **Purpose**: 
  - Serves as a reverse proxy for WordPress
  - Handles SSL/TLS encryption (HTTPS)
  - Routes PHP requests to the WordPress container
  - Serves static files when possible
- **Port**: 443 (HTTPS)
- **Access**: Accessible from the host machine and external network

### 2. **WordPress** (Content Management System)
- **Container name**: `wordpress`
- **Purpose**: 
  - Runs the WordPress CMS using PHP-FPM
  - Handles all WordPress functionality
  - Communicates with MariaDB for data storage
- **Port**: 9000 (internal, PHP-FPM)
- **Access**: Only accessible internally via Nginx

### 3. **MariaDB** (Database)
- **Container name**: `mariadb`
- **Purpose**: 
  - Stores all WordPress data (posts, pages, settings, users, etc.)
  - Provides database services for the WordPress application
- **Port**: 3306 (internal)
- **Access**: Only accessible internally from WordPress container

### How They Work Together

```
Internet → Nginx (443/HTTPS) → WordPress (PHP-FPM) → MariaDB (3306)
                ↓
        Static Files (CSS, JS, Images)
```

## Starting the Project

### Prerequisites Check

Before starting, ensure:
- Docker is installed and running
- Docker Compose is available
- You have created the `.env` file in `srcs/` directory
- You have created password files in `secrets/` directory

### Start All Services

Navigate to the project directory and start all services:

```bash
cd srcs
docker compose up -d
```

The `-d` flag runs containers in detached mode (in the background).

**What happens:**
1. Docker Compose reads `docker-compose.yml`
2. Builds container images if they don't exist
3. Creates the network `inception`
4. Creates volumes for data persistence
5. Starts all three containers in the correct order:
   - MariaDB starts first
   - WordPress waits for MariaDB, then starts
   - Nginx waits for WordPress, then starts

**First-time setup:**
- MariaDB initializes the database and creates users
- WordPress downloads and installs WordPress core files
- WordPress automatically configures the database connection
- WordPress creates the admin user
- Nginx generates SSL certificates

### Verify Services are Running

Check container status:

```bash
docker compose ps
```

You should see all three containers with status "Up":
```
NAME        IMAGE                STATUS
mariadb     inception-mariadb    Up
wordpress   inception-wordpress  Up
nginx       inception-nginx      Up
```

## Stopping the Project

### Stop All Services (Keep Data)

To stop all containers while preserving data:

```bash
cd srcs
docker compose stop
```

This stops containers but keeps them and all volumes intact.

### Stop and Remove Containers (Keep Data)

To stop and remove containers (data remains in volumes):

```bash
cd srcs
docker compose down
```

This removes containers but preserves volumes, so your WordPress site data remains.

### Stop and Remove Everything (Delete Data)

⚠️ **Warning**: This will delete all data including your WordPress site and database!

```bash
cd srcs
docker compose down -v
```

The `-v` flag removes volumes, deleting all persistent data.

## Accessing the Website

### Local Access

If testing on your local machine:

1. **Add domain to hosts file:**
   ```bash
   sudo echo "127.0.0.1 alphbarr.42.fr" >> /etc/hosts
   ```

2. **Access the website:**
   - Open your browser
   - Navigate to: `https://alphbarr.42.fr`
   - Accept the SSL certificate warning (self-signed certificate)

### Remote Access

If the server is accessible from the network:

- Ensure port 443 is open in your firewall
- Access via: `https://alphbarr.42.fr` (or your server's IP)
- Make sure DNS points to your server's IP address

## Accessing the WordPress Administration Panel

### Login Credentials

The default WordPress administrator credentials are:

- **Username**: Set in `.env` file (`WP_ADMIN_USER` variable, default: `admin`)
- **Password**: Same as the database password (stored in `secrets/db_password.txt`)

### Access Admin Panel

1. Navigate to: `https://alphbarr.42.fr/wp-admin`
2. Enter your admin username and password
3. You'll be logged into the WordPress dashboard

### Security Recommendation

**Important**: Change the admin password immediately after first login:
1. Go to Users → Your Profile
2. Scroll down to "Account Management"
3. Click "Set New Password"
4. Create a strong, unique password

## Managing Credentials

### Location of Credentials

#### Database Passwords

Passwords are stored in the `secrets/` directory at the project root:

- **Database root password**: `secrets/db_root_password.txt`
- **WordPress database user password**: `secrets/db_password.txt`

#### WordPress Admin Credentials

- **Username**: Defined in `srcs/.env` as `WP_ADMIN_USER`
- **Password**: Same as `db_password.txt` (initially)
- **Email**: Defined in `srcs/.env` as `WP_ADMIN_EMAIL`

#### Viewing Passwords

To view a password:

```bash
cat secrets/db_password.txt
cat secrets/db_root_password.txt
```

### Changing Passwords

#### Change Database Password

⚠️ **Warning**: Changing database passwords requires updating multiple files and restarting services.

1. Update `secrets/db_password.txt` with new password
2. Update `secrets/db_root_password.txt` if needed
3. Update WordPress configuration:
   ```bash
   docker compose exec wordpress wp config set DB_PASSWORD "new_password" --allow-root
   ```
4. Update MariaDB user password:
   ```bash
   docker compose exec mariadb mysql -u root -p$(cat ../secrets/db_root_password.txt) -e "ALTER USER 'wpuser'@'%' IDENTIFIED BY 'new_password'; FLUSH PRIVILEGES;"
   ```
5. Restart WordPress:
   ```bash
   docker compose restart wordpress
   ```

#### Change WordPress Admin Password

**Via WordPress Dashboard:**
1. Log in to `https://alphbarr.42.fr/wp-admin`
2. Go to Users → Your Profile
3. Scroll to "Account Management"
4. Set new password

**Via Command Line:**
```bash
docker compose exec wordpress wp user update admin --user_pass="new_password" --allow-root
```

### Security Best Practices

- **Never commit secrets to Git**: Ensure `secrets/` directory is in `.gitignore`
- **Use strong passwords**: Minimum 16 characters, mix of letters, numbers, symbols
- **Restrict file permissions**:
  ```bash
  chmod 600 secrets/*.txt
  ```
- **Regularly rotate passwords**: Especially in production environments

## Checking Service Health

### View Container Status

Check if all containers are running:

```bash
cd srcs
docker compose ps
```

Expected output:
```
NAME        IMAGE                STATUS          PORTS
mariadb     inception-mariadb    Up (healthy)    
wordpress   inception-wordpress  Up              
nginx       inception-nginx      Up              0.0.0.0:443->443/tcp
```

### View Container Logs

#### All Services Logs

```bash
docker compose logs
```

#### Specific Service Logs

```bash
# Nginx logs
docker compose logs nginx

# WordPress logs
docker compose logs wordpress

# MariaDB logs
docker compose logs mariadb
```

#### Follow Logs in Real-Time

```bash
docker compose logs -f
```

### Test Website Accessibility

#### From Host Machine

```bash
# Check if Nginx is responding
curl -k https://alphbarr.42.fr

# Check HTTP status code
curl -k -o /dev/null -s -w "%{http_code}\n" https://alphbarr.42.fr
```

Expected: HTTP 200

#### Test Database Connection

```bash
# Test from WordPress container
docker compose exec wordpress mysqladmin ping -h mariadb -u wpuser -p$(cat /run/secrets/db_password)
```

Expected: `mysqld is alive`

#### Test PHP-FPM

```bash
# Check PHP-FPM status
docker compose exec wordpress ps aux | grep php-fpm
```

Expected: PHP-FPM processes should be running

### Verify SSL Certificate

```bash
# View certificate details
echo | openssl s_client -connect alphbarr.42.fr:443 -servername alphbarr.42.fr 2>/dev/null | openssl x509 -noout -dates
```

### Common Issues and Solutions

#### Containers Won't Start

**Check logs:**
```bash
docker compose logs
```

**Common causes:**
- Port 443 already in use: `sudo lsof -i :443`
- Insufficient disk space: `df -h`
- Docker daemon not running: `sudo systemctl status docker`

#### 403 Forbidden Error

If you see a 403 error:
1. Check file permissions in WordPress container
2. Verify Nginx can read WordPress files
3. Check Nginx error logs: `docker compose logs nginx`

#### Database Connection Errors

If WordPress can't connect to database:
1. Verify MariaDB is running: `docker compose ps mariadb`
2. Check database credentials in `.env`
3. Test connection: `docker compose exec wordpress mysqladmin ping -h mariadb`

#### SSL Certificate Errors

If browser shows certificate warnings:
- This is normal for self-signed certificates
- Click "Advanced" → "Proceed to site" in your browser
- For production, use proper SSL certificates from Let's Encrypt or a CA

## Useful Commands Summary

| Task | Command |
|------|---------|
| Start services | `docker compose up -d` |
| Stop services | `docker compose stop` |
| View status | `docker compose ps` |
| View logs | `docker compose logs -f` |
| Restart service | `docker compose restart <service_name>` |
| Execute command in container | `docker compose exec <service_name> <command>` |
| Rebuild containers | `docker compose build` |
| Remove everything | `docker compose down -v` |

## Getting Help

If you encounter issues:

1. Check container logs: `docker compose logs`
2. Verify container status: `docker compose ps`
3. Review the [DEV_DOC.md](DEV_DOC.md) for troubleshooting details
4. Check Docker documentation: https://docs.docker.com/

