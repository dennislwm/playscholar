-include .env

.PHONY: check_env playscribebot scholar
SHELL := /bin/bash
DOCKER_PS := $(shell $(DOCKER) ps 2> /dev/null)

check_env:
ifndef OPENAI_API_KEY
	$(error Environment variable OPENAI_API_KEY not set)
endif
ifndef DOCKER
	$(error Environment variable DOCKER not set)
endif
ifndef DOCKER_IMAGE
	$(error Environment variable DOCKER_IMAGE not set)
endif
ifndef DOCKER_PS
	$(error $(DOCKER) daemon is not running)
endif

playscribebot:
	@source ./make.sh && get_output $(URL)
	@cat output.txt | $(DOCKER) run --rm --env OPENAI_API_KEY=$(OPENAI_API_KEY) -i $(DOCKER_IMAGE) --pattern extract_article_wisdom && rm output.txt

scholar: check_env
	@test $(URL) || ( echo [Usage] make scholar URL=WEB_PAGE_LINK; exit 1 )
	@source ./make.sh && get_output $(URL)
	@cat output.txt | $(DOCKER) run --rm --env-file .env -i $(DOCKER_IMAGE) --pattern extract_article_wisdom && rm output.txt
