# set default shell
SHELL := $(shell which bash)
GROUP_ID = $(shell id -g)
USER_ID = $(shell id -u)

# default shell options
.SHELLFLAGS = -c

.SILENT: ;			   # no need for @
.ONESHELL: ;
.NOTPARALLEL: ;		  # wait for this target to finish
# .EXPORT_ALL_VARIABLES: ; # send all vars to shell
default: help;   # default target

# Make function
# https://stackoverflow.com/questions/10858261/abort-makefile-if-variable-not-set

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined var $1$(if $2, ($2)). Please use $1=value))

help: ## display commands help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help

vendor: ## install repositories and vendors
	docker-compose run --rm mlflow poetry install --remove-untracked
.PHONY: vendor

fixtures: ## Setup everything
	$(MAKE) rm
	docker-compose build
	$(MAKE) up
.PHONY: fixtures

up: ## docker-compose up in daemon mode + process status
	docker-compose up -d --remove-orphans
	$(MAKE) ps
.PHONY: up

ps: ## docker-compose process status
	docker-compose ps
.PHONY: ps

rm: ## stop and delete containers but leave network and volumes
	docker-compose rm -f -v -s
.PHONY: rm

all: rm vendor up ## Do all
.PHONY: all

services: ## List all possible services
	docker-compose config --service
.PHONY: services

_ubuntu:
	docker pull ubuntu
.PHONY: _ubuntu

docker_make: ## Running command inside docker
	@:$(call check_defined, cmd, command)
	echo "Running command inside docker, with home dir $$(echo ~): ${cmd}"
	docker run -it -v $$(pwd):/vdk/ -v $$(echo ~):/root/ -w /vdk ubuntu ${cmd}
.PHONY: docker_make

chown: _ubuntu ## Own your dir ! Don't let root get you !
	$(MAKE) docker_make cmd="chown -R ${USER_ID}:${GROUP_ID} ."
	$(MAKE) docker_make cmd="chmod -R 777 ."
.PHONY: chown

logs: ## Get log from a service
	@:$(call check_defined, svc, service)
	docker-compose logs -t -f ${svc}
.PHONY: logs


