SHELL := /bin/bash
SHELLCHECK ?= shellcheck
IMAGE_NAME ?= dev-setup

.PHONY: bootstrap lint docker-build docker-shell test

bootstrap:
	./bootstrap.sh

lint:
	$(SHELLCHECK) bootstrap.sh

docker-build:
	docker build -t $(IMAGE_NAME) .

docker-shell: docker-build
	docker run --rm -it -v $(PWD):/workspace $(IMAGE_NAME) bash

test: docker-build
	docker run --rm -v $(PWD):/workspace $(IMAGE_NAME) bash -lc "cd /workspace && ./bootstrap.sh --skip-vim-plugins --skip-node --skip-go"
