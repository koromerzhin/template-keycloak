isDocker := $(shell docker info > /dev/null 2>&1 && echo 1)

.DEFAULT_GOAL := help
STACK         := keycloak
NETWORK       := proxynetwork

KEYCLOAK         := $(STACK)_keycloak
KEYCLOAKFULLNAME := $(KEYCLOAK).1.$$(docker service ps -f 'name=$(KEYCLOAK)' $(KEYCLOAK) -q --no-trunc | head -n1)

MARIADB         := $(STACK)_mariadb
MARIADBFULLNAME := $(MARIADB).1.$$(docker service ps -f 'name=$(MARIADB)' $(MARIADB) -q --no-trunc | head -n1)

PHPMYADMIN         := $(STACK)_phpmyadmin
PHPMYADMINFULLNAME := $(PHPMYADMIN).1.$$(docker service ps -f 'name=$(PHPMYADMIN)' $(PHPMYADMIN) -q --no-trunc | head -n1)

SUPPORTED_COMMANDS := contributors git linter docker logs ssh inspect update sleep
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

node_modules:
	@npm install

dump:
	@mkdir dump

folders: dump ## Create folder

.PHONY: isdocker
isdocker: ## Docker is launch
ifeq ($(isDocker), 0)
	@echo "Docker is not launch"
	exit 1
endif

install: folders node_modules ## Installation application
	@make docker deploy -i

logs: isdocker ## Scripts logs
ifeq ($(COMMAND_ARGS),keycloak)
	@docker service logs -f --tail 100 --raw $(KEYCLOAKFULLNAME)
else ifeq ($(COMMAND_ARGS),database)
	@docker service logs -f --tail 100 --raw $(DATABASEFULLNAME)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make logs ARGUMENT"
	@echo "---"
	@echo "keycloak: KEYCLOAK"
	@echo "database: DATABASE"
endif

ssh: isdocker ## SSH
ifeq ($(COMMAND_ARGS),keycloak)
	@docker exec -it $(KEYCLOAKFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker exec -it $(MARIADBFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker exec -it $(PHPMYADMINBFULLNAME) /bin/bash
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make ssh ARGUMENT"
	@echo "---"
	@echo "keycloak: KEYCLOAK"
	@echo "mariadb: DATABASE"
	@echo "phpmyadmin: PHPMYADMIN"
endif

.PHONY: sleep
sleep: ## sleep
	@sleep  $(COMMAND_ARGS)

docker: isdocker ## Scripts docker
ifeq ($(COMMAND_ARGS),create-network)
	@docker network create --driver=overlay $(NETWORK)
else ifeq ($(COMMAND_ARGS),image-pull)
	@more docker-compose.yml | grep image: | sed -e "s/^.*image:[[:space:]]//" | while read i; do docker pull $$i; done
else ifeq ($(COMMAND_ARGS),deploy)
	@docker stack deploy -c docker-compose.yml $(STACK)
else ifeq ($(COMMAND_ARGS),ls)
	@docker stack services $(STACK)
else ifeq ($(COMMAND_ARGS),stop)
	@docker stack rm $(STACK)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make docker ARGUMENT"
	@echo "---"
	@echo "create-network: create network"
	@echo "deploy: deploy"
	@echo "image-pull: Get docker image"
	@echo "ls: docker service"
	@echo "stop: docker stop"
endif

contributors: node_modules ## Contributors
ifeq ($(COMMAND_ARGS),add)
	@npm run contributors add
else ifeq ($(COMMAND_ARGS),check)
	@npm run contributors check
else ifeq ($(COMMAND_ARGS),generate)
	@npm run contributors generate
else
	@npm run contributors
endif

git: node_modules ## Scripts GIT
ifeq ($(COMMAND_ARGS),status)
	@git status
else ifeq ($(COMMAND_ARGS),check)
	@make linter all -i
	@make git status -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make git ARGUMENT"
	@echo "---"
	@echo "check: CHECK before"
	@echo "status: status"
endif

linter: isdocker ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
	@echo "readme: linter README.md"
endif

inspect: isdocker ## docker service inspect
ifeq ($(COMMAND_ARGS),keycloak)
	@docker service inspect $(KEYCLOAK)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker service inspect $(MARIADB)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker service inspect $(PHPMYADMIN)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make inspect ARGUMENT"
	@echo "---"
	@echo "keycloak: KEYCLOAK"
	@echo "mariadb: MARIADB"
	@echo "phpmyadmin: PHPMYADMIN"
endif

update: isdocker ## docker service update
ifeq ($(COMMAND_ARGS),keycloak)
	@docker update inspect $(KEYCLOAK)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker update inspect $(MARIADB)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker update inspect $(PHPMYADMIN)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make update ARGUMENT"
	@echo "---"
	@echo "keycloak: KEYCLOAK"
	@echo "mariadb: MARIADB"
	@echo "phpyadmin: PHPYADMIN"
endif
