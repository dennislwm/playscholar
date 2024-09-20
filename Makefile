-include .env

.PHONY: check_env ci_build docker_clean docker_interactive docker_publish docker_tag docker_verify scholar
SHELL := /bin/bash
DOCKER_PS := $(shell $(DOCKER) ps 2> /dev/null)
DOCKER_MANIFEST := $(shell $(DOCKER) manifest inspect $(REGISTRY_NAME)/$(REGISTRY_USER)/$(DOCKER_IMAGE):$(DOCKER_TAG_VERSION) > /dev/null 2>&1 && echo 1 || echo 0)

check_env:
ifndef OPENAI_API_KEY
	$(error Environment variable OPENAI_API_KEY not set)
endif
ifndef REGISTRY_NAME
	$(error Environment variable REGISTRY_NAME not set)
endif
ifndef REGISTRY_USER
	$(error Environment variable REGISTRY_USER not set)
endif
ifndef REGISTRY_PASS
	$(error Environment variable REGISTRY_PASS not set)
endif
ifndef DOCKER
	$(error Environment variable DOCKER not set)
endif
ifndef DOCKER_IMAGE
	$(error Environment variable DOCKER_IMAGE not set)
endif
ifndef DOCKER_TAG_VERSION
	$(error Environment variable DOCKER_TAG_VERSION not set)
endif
ifndef DOCKER_PS
	$(error $(DOCKER) daemon is not running)
endif

ci_build: check_env
	@DOCKER_BUILDKIT=1 $(DOCKER) build -t $(DOCKER_IMAGE):latest .

docker_clean: check_env
	@$(DOCKER) image prune -f

docker_interactive: check_env
	@$(DOCKER) run --rm --env-file .env -it --entrypoint bash $(DOCKER_IMAGE):latest

docker_publish: docker_tag
	@echo $(REGISTRY_PASS) | $(DOCKER) login $(REGISTRY_NAME) -u $(REGISTRY_USER) --password-stdin
	@if [ $(DOCKER_MANIFEST) -eq 1 ]; then echo "[Error] Docker manifest exists."; exit 1; fi
	@test $(APPROVE) || ( echo [Usage] make docker_publish APPROVE=yes; exit 1 )
	@$(DOCKER) push $(REGISTRY_NAME)/$(REGISTRY_USER)/$(DOCKER_IMAGE):$(DOCKER_TAG_VERSION)

docker_tag: check_env
	$(DOCKER) tag $(DOCKER_IMAGE):latest $(REGISTRY_NAME)/$(REGISTRY_USER)/$(DOCKER_IMAGE):$(DOCKER_TAG_VERSION)

docker_verify: check_env
	@$(DOCKER) run --rm --env-file .env -i $(DOCKER_IMAGE):latest --listmodels

scholar: check_env
	@test $(URL) || ( echo [Usage] make scholar URL=WEB_PAGE_LINK; exit 1 )
	@source ./make.sh && get_output $(URL)
	@cat output.txt | $(DOCKER) run --rm --env-file .env -i $(DOCKER_IMAGE):latest --pattern extract_article_wisdom && rm output.txt
