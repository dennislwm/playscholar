-include .env

.PHONY: check_env ci_build docker_clean docker_interactive docker_publish docker_tag docker_verify list pattern doc scholar
.PHONY: _docker_interactive _docker_publish _docker_tag _docker_verify _list _pattern _doc _scholar
SHELL := /bin/bash
VR := set -a && eval "$$(lpass show --notes 'playscholar/env')" && set +a &&
DOCKER_PS := $(shell $(DOCKER) ps 2> /dev/null)
OUTPUT := $(shell head -c 1024 /dev/urandom | base64 | tr -cd "[:upper:][:digit:][:lower:]" | head -c 6 )

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
	@$(VR) $(MAKE) _docker_interactive

_docker_interactive:
	@$(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -it --entrypoint bash $(DOCKER_IMAGE):latest

docker_publish: docker_tag
	@$(VR) $(MAKE) _docker_publish APPROVE=$(APPROVE)

_docker_publish:
	@echo $$REGISTRY_PASS | $(DOCKER) login $$REGISTRY_NAME -u $$REGISTRY_USER --password-stdin
	@if $(DOCKER) manifest inspect $$REGISTRY_NAME/$$REGISTRY_USER/$(DOCKER_IMAGE):$(DOCKER_TAG_VERSION) > /dev/null 2>&1; then echo "[Error] Docker manifest exists."; exit 1; fi
	@test $(APPROVE) || ( echo [Usage] make docker_publish APPROVE=yes; exit 1 )
	@$(DOCKER) push $$REGISTRY_NAME/$$REGISTRY_USER/$(DOCKER_IMAGE):$(DOCKER_TAG_VERSION)

docker_tag: check_env
	@$(VR) $(MAKE) _docker_tag

_docker_tag:
	$(DOCKER) tag $(DOCKER_IMAGE):latest $$REGISTRY_NAME/$$REGISTRY_USER/$(DOCKER_IMAGE):$(DOCKER_TAG_VERSION)

docker_verify: check_env
	@$(VR) $(MAKE) _docker_verify

_docker_verify:
	@$(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --listmodels

list: check_env
	@$(VR) $(MAKE) _list

_list:
	@$(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" $(DOCKER_IMAGE):latest -n 1000

pattern: check_env
	@test $(URL) || ( echo [Usage] make pattern URL=WEB_PAGE_LINK; exit 1 )
	@test $(PAT) || ( echo [Usage] make pattern URL=WEB_PAGE_LINK PAT=FABRIC_PATTERN; exit 1 )
	@$(VR) $(MAKE) _pattern URL=$(URL) PAT=$(PAT) OUTPUT=$(OUTPUT)

_pattern:
	@source ./make.sh && get_output $(URL) $(OUTPUT)
	@cat $(OUTPUT).txt | $(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --pattern $(PAT) && rm $(OUTPUT).txt

doc: check_env
	@test $(DOC) || ( echo [Usage] make doc DOC=FILE_PATH; exit 1 )
	@$(VR) $(MAKE) _doc DOC=$(DOC)

_doc:
	@echo "# ELI5"
	@cat $(DOC) | $(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --pattern create_story_explanation
	@echo ""
	@cat $(DOC) | $(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --pattern extract_controversial_ideas
	@echo ""
	@cat $(DOC) | $(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --pattern extract_article_wisdom

scholar: check_env
	@test $(URL) || ( echo [Usage] make scholar URL=WEB_PAGE_LINK; exit 1 )
	@$(VR) $(MAKE) _scholar URL=$(URL) OUTPUT=$(OUTPUT)

_scholar:
	@source ./make.sh && get_output $(URL) $(OUTPUT)
	@echo "# ELI5"
	@cat $(OUTPUT).txt | $(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --pattern create_story_explanation
	@echo ""
	@cat $(OUTPUT).txt | $(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --pattern extract_controversial_ideas
	@echo ""
	@cat $(OUTPUT).txt | $(DOCKER) run --rm -e OPENAI_API_KEY="$$OPENAI_API_KEY" -i $(DOCKER_IMAGE):latest --pattern extract_article_wisdom && rm $(OUTPUT).txt
