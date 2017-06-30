#!make
include .env
export $(shell sed 's/=.*//' .env)

.PHONY: clone rebuild up stop restart status console-app console-db console-nginx clean help

docker-env: clone nginx-config ssl database-config config-json npm-install hosts up permissions

dialog:
	@bash ./dialog.sh
nginx-config:
	@. ./nginx-config.sh
ssl:
	@openssl genrsa -out nginx/ssl/${SERVER_NAME}.key 2048
	@openssl req -new -x509 -key nginx/ssl/${SERVER_NAME}.key -out nginx/ssl/${SERVER_NAME}.cert -days 3650 -subj /CN=${SERVER_NAME}

clone:
	@echo "\n\033[1;m Cloning App (${BRANCH_NAME} branch) \033[0m"
	@if cd src 2> /dev/null; then git pull; else git clone -b ${BRANCH_NAME} ${GIT_URL} src; fi
	@if cd umbrella-plugins 2> /dev/null; then git pull; else git clone -b ${WP_BRANCH_NAME} ${WP_GIT_URL} umbrella-plugins; fi

rebuild: stop
	@echo "\n\033[1;m Rebuilding containers... \033[0m"
	docker-compose build --no-cache

up:
	@echo "\n\033[1;m Spinning up docker ${BRANCH_NAME} environment... \033[0m"
	docker-compose up -d 
	@$(MAKE) --no-print-directory status

npm-install:
	@docker-compose run backend yarn

pull:
	@if cd src 2> /dev/null; then git pull; else git clone -b ${BRANCH_NAME} ${GIT_URL} src; fi
	@if cd umbrella-plugins 2> /dev/null; then git pull; else git clone -b ${WP_BRANCH_NAME} ${WP_GIT_URL} umbrella-plugins; fi
	@docker-compose exec backend yarn
	@$(MAKE) --no-print-directory restart
	@$(MAKE) --no-print-directory permissions

hosts:
	@echo "\n\033[1;m Adding record in to your local hosts file.\033[0m"
	@echo "\n\033[1;m Please use your local sudo password.\033[0m"
	@echo '127.0.0.1 localhost '${SERVER_NAME}' www.'${SERVER_NAME}' admin.'${SERVER_NAME}' www.admin.'${SERVER_NAME}'' | sudo tee -a /etc/hosts

stop:
	@echo "\n\033[1;m  Halting containers... \033[0m"
	@docker-compose stop
	@$(MAKE) --no-print-directory status

restart:
	@echo "\n\033[1;m Restarting containers... \033[0m"
	@docker-compose stop
	@docker-compose up -d
	@$(MAKE) --no-print-directory status

status:
	@echo "\n\033[1;m Containers statuses \033[0m"
	@docker-compose ps

clean:
	@echo "\033[1;31m\033[5m *** Removing containers and Application (./src)! ***\033[0m"
	@echo "\033[1;31m\033[5m\t*** Ensure that you commited changes!*** \033[0m"
	@$(MAKE) --no-print-directory dialog
	@rm -rf src/ nginx/configs/conf.d/*.conf nginx/ssl/*.cert nginx/ssl/*.key nginx/configs/.htpasswd
	@docker-compose down --rmi all 2> /dev/null
	@$(MAKE) --no-print-directory status

console-app:
	@docker-compose exec app bash
console-db:
	@docker-compose exec db bash
console-web-srv:
	@docker-compose exec web-srv bash
console-backend:
	@docker-compose exec backend bash
console-redis:
	@docker-compose exec redis redis-cli
	
schema-update:
	@docker-compose exec app bash -c "cd /var/www/html/${APP_NAME}/ && php bin/console doctrine:schema:update --force"

logs-web-srv:
	@docker-compose logs --tail=100 -f web-srv
logs-node:
	@docker-compose logs --tail=100 -f backend

help:
	@echo "\033[1;32mdocker-env\t\t- Main scenario, used by default\033[0m"

	@echo "\n\033[1mMain section\033[0m"
	@echo "clone\t\t\t- clone Application and WP repo"
	@echo "pull\t\t\t- pull Application  and WP repo and restart environment"
	@echo "rebuild\t\t\t- build containers w/o cache"
	@echo "up\t\t\t- start project"
	@echo "stop\t\t\t- stop project"
	@echo "restart\t\t\t- restart containers"
	@echo "status\t\t\t- show status of containers"
	@echo "nginx-config\t\t- generates nginx config file based on .env parameters"
	@echo "database-config\t\t- provides grants to app user"
	@echo "npm-install\t\t- install packajes"
	@echo "hosts\t\t\t- add record set in /etc/hosts file (For local development environments ONLY!)"
	@echo "ssl\t\t\t- Gerates self-signed ssl certificate"

	@echo "\n\033[1;31m\033[5mclean\t\t\t- Reset project. All Local application data will be lost!\033[0m"

	@echo "\n\033[1mConsole section\033[0m"
	@echo "console-app\t\t- provides bash console to wordpress container"
	@echo "console-db\t\t- provides bash console to mysql container"
	@echo "console-web-srv\t\t- provides bash console to nginx container"
	@echo "console-backend\t\t- provides bash console to backend container"

	@echo "\n\033[1mLogs section\033[0m"
	@echo "logs-nginx\t\t- show nginx logs"
	@echo "logs-db\t\t\t- show database logs"
	@echo "logs-app\t\t- show php logs"
	@echo "logs-backend\t\t- show node logs"
	@echo "\n\033[0;33mhelp\t\t\t- show this menu\033[0m"
