# Inception — root Makefile
# Replace LOGIN below with your 42/Hive login before first build.

LOGIN		?= pnurmi
DATA_DIR	= /home/$(LOGIN)/data
MARIADB_DIR	= $(DATA_DIR)/mariadb
WORDPRESS_DIR	= $(DATA_DIR)/wordpress
COMPOSE_FILE	= srcs/docker-compose.yml

# Old hardware: single parallel build, modest Docker memory
export DOCKER_BUILDKIT		= 0
export COMPOSE_PARALLEL_LIMIT	= 1

RESET	= \033[0m
GREEN	= \033[1;32m
BLUE	= \033[1;34m
YELLOW	= \033[1;33m
RED	= \033[1;31m

all: data-dirs
	@echo "$(YELLOW)==> Building and starting Inception...$(RESET)"
	@$(MAKE) images
	@$(MAKE) up
	@echo "$(GREEN)==> Done. Visit https://$(LOGIN).42.fr$(RESET)"

data-dirs:
	@echo "$(YELLOW)==> Creating bind-mount data directories...$(RESET)"
	@mkdir -p $(MARIADB_DIR) $(WORDPRESS_DIR)

images:
	@echo "$(BLUE)==> Building Docker images (single-threaded for slow hosts)...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) build --parallel 1

up:
	@echo "$(BLUE)==> Starting containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up -d

down:
	@echo "$(RED)==> Stopping containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

ps:
	@docker compose -f $(COMPOSE_FILE) ps

status:
	@./scripts/check-services.sh

clean:
	@echo "$(RED)==> Removing containers, images, and named volumes...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down --rmi all -v

fclean: clean
	@echo "$(RED)==> Removing host data directories...$(RESET)"
	@sudo rm -rf $(DATA_DIR)
	@docker system prune -f --volumes

re: fclean all

env:
	@./scripts/configure-env.sh $(LOGIN)

hosts:
	@./scripts/setup-hosts.sh $(LOGIN)

.PHONY: all data-dirs images up down logs ps status clean fclean re env hosts
