*This project has been created as part of the 42 curriculum by alphbarry.*

# Inception

## Description

**Inception** is a system administration project that demonstrates the deployment of a complete web application stack using Docker containers. The project sets up a WordPress website running behind an Nginx reverse proxy with SSL/TLS encryption, all connected to a MariaDB database.

### Goal

The primary goal of this project is to learn and demonstrate:
- Containerization concepts using Docker
- Orchestration with Docker Compose
- Secure deployment practices (SSL certificates, secrets management)
- Network configuration and service communication
- Volume management for data persistence
- Web server configuration (Nginx with SSL)
- Database setup and management (MariaDB)

### Overview

The project implements a three-tier architecture:
- **Nginx**: Reverse proxy and SSL termination, serving static content and forwarding PHP requests
- **WordPress**: PHP-FPM application server running WordPress CMS
- **MariaDB**: Relational database management system storing WordPress data

All services run in isolated Docker containers, communicate through a custom bridge network, and use Docker volumes for data persistence.

## Instructions

### Prerequisites

- Docker Engine (version 20.10 or higher)
- Docker Compose (v2 recommended, or v1.29+)
- Git
- Basic knowledge of Linux command line

For detailed Docker installation instructions, see [INSTALL_DOCKER.md](INSTALL_DOCKER.md).

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Inception
   ```

2. **Set up environment variables:**
   Create a `.env` file in the `srcs/` directory with the following variables:
   ```bash
   DOMAIN_NAME=alphbarr.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wpuser
   WP_TITLE=Inception WordPress Site
   WP_ADMIN_USER=admin
   WP_ADMIN_EMAIL=admin@alphbarr.42.fr
   WP_USER=editor
   WP_USER_EMAIL=editor@alphbarr.42.fr
   ```

3. **Set up secrets:**
   Create password files in the `secrets/` directory:
   ```bash
   echo "your_secure_db_root_password" > secrets/db_root_password.txt
   echo "your_secure_db_password" > secrets/db_password.txt
   ```

4. **Build and start the services:**
   ```bash
   cd srcs
   docker compose build
   docker compose up -d
   ```

5. **Access the website:**
   - Website: `https://alphbarr.42.fr`
   - WordPress Admin: `https://alphbarr.42.fr/wp-admin`
   - Add `127.0.0.1 alphbarr.42.fr` to `/etc/hosts` if testing locally

For more detailed instructions, see [USER_DOC.md](USER_DOC.md) and [DEV_DOC.md](DEV_DOC.md).

## Project Description

### Docker Usage

This project leverages Docker for containerization, allowing each service to run in an isolated environment with its own dependencies. Docker containers provide:

- **Isolation**: Each service runs independently with its own filesystem and network namespace
- **Portability**: The entire stack can run identically on any system with Docker installed
- **Resource Efficiency**: Containers share the host OS kernel, using less resources than virtual machines
- **Reproducibility**: Dockerfiles ensure consistent builds across different environments

### Sources Included

The project structure includes:

- **`srcs/docker-compose.yml`**: Orchestration file defining services, networks, volumes, and secrets
- **`srcs/requirements/nginx/`**: Nginx reverse proxy container
  - `Dockerfile`: Builds Alpine-based Nginx image with SSL support
  - `conf/nginx.conf`: Nginx configuration for SSL termination and PHP-FPM proxying
  - `tools/generate_ssl.sh`: Script to generate self-signed SSL certificates
- **`srcs/requirements/wordpress/`**: WordPress PHP-FPM container
  - `Dockerfile`: Builds Alpine-based PHP-FPM image with WordPress dependencies
  - `tools/wp_setup.sh`: Script to download WordPress and configure it on first run
- **`srcs/requirements/mariadb/`**: MariaDB database container
  - `Dockerfile`: Builds Alpine-based MariaDB image
  - `tools/init_db.sh`: Script to initialize database and create WordPress user
- **`secrets/`**: Directory containing sensitive password files (should be in .gitignore)

### Main Design Choices

1. **Alpine Linux base images**: Chosen for minimal size and security, reducing attack surface
2. **Multi-stage setup scripts**: Initialization scripts handle first-run configuration automatically
3. **Named volumes**: Used for data persistence, allowing containers to be recreated without data loss
4. **Bridge network**: Custom Docker network isolates services while allowing communication
5. **SSL/TLS termination**: Nginx handles SSL, offloading encryption from PHP-FPM
6. **Secrets management**: Docker secrets used for sensitive passwords instead of environment variables
7. **User permissions**: Both Nginx and PHP-FPM run as `www-data` user for security and file access

### Comparisons

#### Virtual Machines vs Docker

**Virtual Machines:**
- Full OS emulation with hypervisor
- Heavy resource usage (RAM, disk, CPU)
- Slower startup times (minutes)
- Complete isolation and security
- Larger image sizes (GBs)
- Better for running different operating systems

**Docker Containers:**
- OS-level virtualization sharing host kernel
- Lightweight resource usage
- Fast startup times (seconds)
- Process-level isolation
- Small image sizes (MBs)
- Better for application deployment and microservices

**Choice Rationale**: Docker is chosen here because we need lightweight, fast containers for a web application stack running on the same OS. VMs would add unnecessary overhead and complexity.

#### Secrets vs Environment Variables

**Environment Variables:**
- Visible in container inspection (`docker inspect`)
- Appear in process lists (`ps aux`)
- Logged in various places (shell history, Docker logs)
- Easy to accidentally expose (in Dockerfiles, docker-compose.yml)
- No encryption at rest
- Simple to use

**Docker Secrets:**
- Stored separately from container definitions
- Mounted as files in `/run/secrets/` (read-only)
- Not visible in process lists or environment inspection
- Can be encrypted at rest
- Better security practices
- Slightly more complex setup

**Choice Rationale**: Secrets are used for database passwords because they contain sensitive credentials that shouldn't be visible in container metadata or logs. Environment variables are used for non-sensitive configuration like database names and usernames.

#### Docker Network vs Host Network

**Docker Bridge Network (Custom):**
- Isolation: Services only accessible within the network
- Port mapping required for external access
- DNS-based service discovery (service names as hostnames)
- Network policies and segmentation possible
- Security: Internal services not exposed to host network
- Better for multi-container applications

**Host Network:**
- Direct access to host network stack
- No port mapping needed
- No DNS-based service discovery
- Less isolation and security
- Simpler networking
- Better for single-container or performance-critical applications

**Choice Rationale**: A custom bridge network (`inception`) is used to isolate services while allowing them to communicate using service names (e.g., `mariadb`, `wordpress`). This provides better security and follows Docker best practices.

#### Docker Volumes vs Bind Mounts

**Docker Volumes:**
- Managed by Docker (created in `/var/lib/docker/volumes/`)
- Platform independent
- Can be backed up/restored with Docker commands
- Better performance on Linux
- Volume lifecycle independent of containers
- More portable across systems
- Anonymous or named volumes

**Bind Mounts:**
- Direct mapping to host filesystem paths
- Platform dependent (path differences)
- Managed manually by user
- Immediate visibility on host
- Useful for development (live code editing)
- Less portable
- Security concerns (permissions, SELinux)

**Choice Rationale**: Named Docker volumes (`mariadb_data`, `wordpress_data`) are used because:
- Data persistence is required regardless of container lifecycle
- Better performance for database operations
- Automatic management and backup capabilities
- No need for direct host filesystem access in production
- More secure (Docker manages permissions)

## Resources

### Documentation

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/support/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [Docker Networks](https://docs.docker.com/network/)

### Articles and Tutorials

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WordPress Security Hardening](https://wordpress.org/support/article/hardening-wordpress/)
- [Container Security](https://docs.docker.com/engine/security/)

### AI Usage

AI assistance was used in the following parts of this project:

- **Configuration debugging**: AI helped identify and resolve permission issues (403 errors) between Nginx and WordPress containers by analyzing user/group configurations
- **Documentation structure**: AI assisted in structuring and formatting the README and documentation files according to project requirements
- **Best practices validation**: AI provided guidance on Docker best practices for security, networking, and volume management
- **Code review**: AI helped review Dockerfiles and scripts for optimization and security improvements

**Note**: While AI was used as a development aid, all architectural decisions, code implementations, and final configurations were reviewed and validated by the project author.
