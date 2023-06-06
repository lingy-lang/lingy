SHELL := bash

ROOT_PERL := $(shell pwd)

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

test ?= test/
v ?= -v

export RELEASE_BRANCH := main

export PATH := $(ROOT_PERL)/bin:$(PATH)

export LINGY_EXEC := $(ROOT_PERL)/bin/_lingy.pl


default:

.PHONY: test
test:
	prove -l $v $(test)

$(ZILD):
	zild $@
