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

test ?= test/
v ?= -v

default:

.PHONY: test
test:
	prove -l $v $(test)

$(ZILD):
	zild $@
