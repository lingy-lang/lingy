SHELL := bash

ZILD := \
    clean \
    cpan \
    cpanshell \
    dist \
    distdir \
    distshell \
    disttest \
    install \
    release \
    update \

DOCKER_IMAGE := lingy-perl
DOCKER_HISTORY := /tmp/lingy-docker-bash-history

test ?= test/
v ?= -v


default:

.PHONY: test
test:
	prove -l $v $(test)

$(ZILD):
	zild $@

docker-test: docker-build
	$(call docker-run,make test)

docker-shell: docker-build
	$(call docker-run,bash)

docker-repl: docker-build
	$(call docker-run,./bin/lingy)

docker-build:
	docker build -t $(DOCKER_IMAGE) .

define docker-run
touch $(DOCKER_HISTORY)
docker run -it --rm \
    -v $$(dirname $$PWD):/host \
    -v $(DOCKER_HISTORY):/root/.bash_history \
    -w /host/perl \
    $(DOCKER_IMAGE) \
    $1
endef
