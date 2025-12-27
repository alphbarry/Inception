# Makefile for Inception Project
# This Makefile provides convenient commands for managing the Docker stack

# Colors for output
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

# Variables
COMPOSE_FILE = srcs/docker-compose.yml
COMPOSE = docker compose -f $(COMPOSE_FILE)

.PHONY: help build up down restart logs ps clean re fclean all

# Default target
all: help

help: ## Show this help message
	@echo "$(GREEN)Available commands:$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2}'

build: ## Build all Docker images
	@echo "$(GREEN)Building Docker images...$(RESET)"
	@cd srcs && docker compose build

build-no-cache: ## Build all Docker images without cache
	@echo "$(GREEN)Building Docker images (no cache)...$(RESET)"
	@cd srcs && docker compose build --no-cache

up: ## Start all containers in detached mode
	@echo "$(GREEN)Starting containers...$(RESET)"
	@cd srcs && docker compose up -d

down: ## Stop and remove containers (volumes preserved)
	@echo "$(YELLOW)Stopping containers...$(RESET)"
	@cd srcs && docker compose down

down-v: ## Stop and remove containers and volumes (⚠️  deletes data)
	@echo "$(YELLOW)⚠️  WARNING: This will delete all data!$(RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd srcs && docker compose down -v; \
	fi

restart: ## Restart all containers
	@echo "$(GREEN)Restarting containers...$(RESET)"
	@cd srcs && docker compose restart

ps: ## Show status of all containers
	@cd srcs && docker compose ps

logs: ## Show logs from all containers
	@cd srcs && docker compose logs -f

logs-nginx: ## Show logs from Nginx container
	@cd srcs && docker compose logs -f nginx

logs-wordpress: ## Show logs from WordPress container
	@cd srcs && docker compose logs -f wordpress

logs-mariadb: ## Show logs from MariaDB container
	@cd srcs && docker compose logs -f mariadb

status: ps ## Alias for ps

stop: ## Stop all containers (containers remain)
	@echo "$(YELLOW)Stopping containers...$(RESET)"
	@cd srcs && docker compose stop

start: ## Start stopped containers
	@echo "$(GREEN)Starting containers...$(RESET)"
	@cd srcs && docker compose start

exec-nginx: ## Execute shell in Nginx container
	@cd srcs && docker compose exec nginx /bin/sh

exec-wordpress: ## Execute shell in WordPress container
	@cd srcs && docker compose exec wordpress /bin/sh

exec-mariadb: ## Execute shell in MariaDB container
	@cd srcs && docker compose exec mariadb /bin/sh

test-nginx: ## Test Nginx configuration
	@cd srcs && docker compose exec nginx nginx -t

rebuild: build restart ## Rebuild images and restart containers

re: down build up ## Stop, rebuild, and start (full restart)
	@echo "$(GREEN)Full restart completed!$(RESET)"

clean: down ## Stop and remove containers (alias for down)

fclean: down-v ## Stop, remove containers and volumes (⚠️  deletes data)

volumes: ## List all volumes
	@echo "$(GREEN)Project volumes:$(RESET)"
	@cd srcs && docker compose config --volumes

volumes-inspect: ## Inspect volume details
	@echo "$(GREEN)WordPress volume:$(RESET)"
	@docker volume inspect inception_wordpress_data 2>/dev/null || echo "Volume not found"
	@echo ""
	@echo "$(GREEN)MariaDB volume:$(RESET)"
	@docker volume inspect inception_mariadb_data 2>/dev/null || echo "Volume not found"

network: ## Show network information
	@echo "$(GREEN)Network information:$(RESET)"
	@docker network inspect inception_inception 2>/dev/null || echo "Network not found"

backup: ## Backup WordPress and MariaDB data
	@echo "$(GREEN)Creating backup...$(RESET)"
	@mkdir -p backups
	@DATE=$$(date +%Y%m%d_%H%M%S); \
	docker run --rm \
		-v inception_wordpress_data:/data \
		-v $$(pwd)/backups:/backup \
		alpine tar czf /backup/wordpress_$$DATE.tar.gz -C /data . && \
	docker run --rm \
		-v inception_mariadb_data:/data \
		-v $$(pwd)/backups:/backup \
		alpine tar czf /backup/mariadb_$$DATE.tar.gz -C /data . && \
	echo "$(GREEN)Backup completed in backups/ directory$(RESET)"

restore: ## Restore from backup (usage: make restore BACKUP_DATE=20240101_120000)
	@if [ -z "$(BACKUP_DATE)" ]; then \
		echo "$(YELLOW)Usage: make restore BACKUP_DATE=20240101_120000$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)⚠️  WARNING: This will overwrite existing data!$(RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		if [ -f "backups/wordpress_$(BACKUP_DATE).tar.gz" ]; then \
			echo "$(GREEN)Restoring WordPress...$(RESET)"; \
			docker run --rm \
				-v inception_wordpress_data:/data \
				-v $$(pwd)/backups:/backup \
				alpine sh -c "cd /data && tar xzf /backup/wordpress_$(BACKUP_DATE).tar.gz"; \
		fi; \
		if [ -f "backups/mariadb_$(BACKUP_DATE).tar.gz" ]; then \
			echo "$(GREEN)Restoring MariaDB...$(RESET)"; \
			docker run --rm \
				-v inception_mariadb_data:/data \
				-v $$(pwd)/backups:/backup \
				alpine sh -c "cd /data && tar xzf /backup/mariadb_$(BACKUP_DATE).tar.gz"; \
		fi; \
		echo "$(GREEN)Restore completed!$(RESET)"; \
	fi

prune: ## Remove unused Docker resources
	@echo "$(YELLOW)Removing unused Docker resources...$(RESET)"
	@docker system prune -f

prune-all: ## Remove all unused Docker resources including volumes (⚠️  dangerous)
	@echo "$(YELLOW)⚠️  WARNING: This will remove all unused Docker resources!$(RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker system prune -a --volumes -f; \
	fi

info: ## Show project information
	@echo "$(GREEN)=== Inception Project Information ===$(RESET)"
	@echo ""
	@echo "$(GREEN)Containers:$(RESET)"
	@cd srcs && docker compose ps
	@echo ""
	@echo "$(GREEN)Volumes:$(RESET)"
	@cd srcs && docker compose config --volumes
	@echo ""
	@echo "$(GREEN)Network:$(RESET)"
	@docker network ls | grep inception || echo "No inception network found"

