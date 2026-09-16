# Docker commands
DOCKER_COMPOSE := docker compose
DOCKER_EXEC := $(DOCKER_COMPOSE) exec app
CONTAINER_NAME := app
# Octane 起動前 (vendor 未インストール等) のコンテナでコマンドを実行する
DOCKER_RUN := $(DOCKER_COMPOSE) run --rm $(CONTAINER_NAME)

.PHONY: up build create-project install-recommend-packages init remake stop down down-v restart destroy ps logs logs-watch log-app log-app-watch app migrate seed rollback-test tinker test test-all test-coverage optimize optimize-clear cache cache-clear ide-helper pint check-pint phpstan rector check-rector install-packages-laravel-pint install-packages-laravel-ide-helper install-packages-larastan octane-reload octane-status

up:
	$(DOCKER_COMPOSE) up -d
build:
	$(DOCKER_COMPOSE) build --no-cache --force-rm
create-project:
	@make build
	rm -f src/.gitignore
	$(DOCKER_RUN) composer create-project --prefer-dist laravel/laravel .
	$(DOCKER_RUN) php artisan key:generate
	$(DOCKER_RUN) php artisan storage:link
	$(DOCKER_RUN) composer require laravel/octane
	$(DOCKER_RUN) php artisan octane:install --server=frankenphp
	@make up
install-recommend-packages:
	$(DOCKER_EXEC) composer require doctrine/dbal
	@make install-packages-laravel-ide-helper
	$(DOCKER_EXEC) composer require --dev barryvdh/laravel-debugbar
	$(DOCKER_EXEC) php artisan vendor:publish --provider="Barryvdh\Debugbar\ServiceProvider"
	@make install-packages-laravel-pint
	@make install-packages-larastan
init:
	$(DOCKER_COMPOSE) build
	$(DOCKER_RUN) composer install
	$(DOCKER_RUN) cp .env.example .env
	$(DOCKER_RUN) php artisan key:generate
	$(DOCKER_RUN) php artisan storage:link
	@make up
remake:
	@make destroy
	@make init
stop:
	$(DOCKER_COMPOSE) stop
down:
	$(DOCKER_COMPOSE) down --remove-orphans
down-v:
	$(DOCKER_COMPOSE) down --remove-orphans --volumes
restart:
	@make down
	@make up
destroy:
	$(DOCKER_COMPOSE) down --rmi all --volumes --remove-orphans
ps:
	$(DOCKER_COMPOSE) ps
logs:
	$(DOCKER_COMPOSE) logs
logs-watch:
	$(DOCKER_COMPOSE) logs --follow
log-app:
	$(DOCKER_COMPOSE) logs $(CONTAINER_NAME)
log-app-watch:
	$(DOCKER_COMPOSE) logs --follow $(CONTAINER_NAME)
app:
	$(DOCKER_EXEC) bash
migrate:
	$(DOCKER_EXEC) php artisan migrate
seed:
	$(DOCKER_EXEC) php artisan db:seed
rollback-test:
	$(DOCKER_EXEC) php artisan migrate:fresh
	$(DOCKER_EXEC) php artisan migrate:refresh
tinker:
	$(DOCKER_EXEC) php artisan tinker
test:
	$(DOCKER_EXEC) php artisan test --tia
test-all:
	$(DOCKER_EXEC) php artisan test
test-coverage:
	$(DOCKER_EXEC) php artisan test --coverage
optimize:
	$(DOCKER_EXEC) php artisan optimize
optimize-clear:
	$(DOCKER_EXEC) php artisan optimize:clear
cache:
	$(DOCKER_EXEC) composer dump-autoload -o
	@make optimize
	$(DOCKER_EXEC) php artisan event:cache
	$(DOCKER_EXEC) php artisan view:cache
cache-clear:
	$(DOCKER_EXEC) composer clear-cache
	@make optimize-clear
	$(DOCKER_EXEC) php artisan event:clear
ide-helper:
	$(DOCKER_EXEC) php artisan clear-compiled
	$(DOCKER_EXEC) php artisan ide-helper:generate
	$(DOCKER_EXEC) php artisan ide-helper:meta
	$(DOCKER_EXEC) php artisan ide-helper:models --write
pint:
	$(DOCKER_EXEC) composer pint
check-pint:
	$(DOCKER_EXEC) composer check-pint
phpstan:
	$(DOCKER_EXEC) composer phpstan
rector:
	$(DOCKER_EXEC) composer rector
check-rector:
	$(DOCKER_EXEC) composer check-rector
install-packages-laravel-pint:
	$(DOCKER_EXEC) composer require laravel/pint --dev
	if type "jq" > /dev/null 2>&1; then \
		cp ./composer.json ./composer.json.tmp; \
		jq --indent 4 '.scripts |= .+{"pint": "./vendor/bin/pint -v", "check-pint": "./vendor/bin/pint --test"}' ./composer.json.tmp  > ./composer.json; \
		rm -f ./composer.json.tmp; \
	fi
install-packages-laravel-ide-helper:
	$(DOCKER_EXEC) composer require --dev barryvdh/laravel-ide-helper
	@make ide-helper
install-packages-larastan:
	$(DOCKER_EXEC) composer require --dev "larastan/larastan:^3.0"
	if type "jq" > /dev/null 2>&1; then \
		cp ./composer.json ./composer.json.tmp; \
		jq --indent 4 '.scripts |= .+{"phpstan": "./vendor/bin/phpstan analyse"}' ./composer.json.tmp  > ./composer.json; \
		rm -f ./composer.json.tmp; \
	fi
octane-reload:
	$(DOCKER_EXEC) php artisan octane:reload
octane-status:
	$(DOCKER_EXEC) php artisan octane:status
