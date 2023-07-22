SHELL := bash

ROOT_PERL := $(shell pwd)

ZILD := \
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

CLOJURE_REPO := https://raw.githubusercontent.com/clojure/clojure
CLOJURE_TAG := clojure-1.11.1
CLOJURE_SOURCE_DIR := $(CLOJURE_REPO)/$(CLOJURE_TAG)/src/clj
CLOJURE_CORE := clojure/core.clj
CLOJURE_CORE_SOURCE := $(CLOJURE_SOURCE_DIR)/$(CLOJURE_CORE)
TMP_CLOJURE_CORE := /tmp/$(CLOJURE_CORE)
LINGY_CLOJURE_CORE := lib/Lingy/core.clj

NREPL_LOG_FILE := .nrepl-log
NREPL_PID_FILE := .nrepl-pid
NREPL_PORT_FILE := .nrepl-port

DEPS := \
    $(LINGY_CLOJURE_CORE)

.DELETE_ON_ERROR:

#------------------------------------------------------------------------------
default:

build: $(DEPS)

.PHONY: test
test: $(DEPS)
	prove -l $v $(test)

$(ZILD): $(DEPS)
	zild $@

clean:
	$(RM) -r Lingy-* cpan
	$(RM) -r .calva/ .clj-kondo/ .lsp/
	$(RM) $(NREPL_LOG_FILE) $(NREPL_PORT_FILE)
	$(RM) $(TMP_CLOJURE_CORE)

#------------------------------------------------------------------------------
nrepl: nrepl-kill
	LINGY_NREPL_LOG_FILE=1 lingy --nrepl & echo $$! > $(NREPL_PID_FILE)
	@echo "*** lingy nREPL Running... (pid $$(< $(NREPL_PID_FILE)))"
	@echo
	@sleep 0.5
	@echo

nrepl-kill:
ifneq (,$(wildcard $(NREPL_PID_FILE)))
	@echo "*** lingy nREPL Stopping... (pid $$(< $(NREPL_PID_FILE)))"
	-kill -9 $$(< $(NREPL_PID_FILE))
	$(RM) $(NREPL_PID_FILE) $(NREPL_LOG_FILE) $(NREPL_PORT_FILE)
	@echo
endif

nrepl-tail:
	tail -f $(NREPL_LOG_FILE)

#------------------------------------------------------------------------------
$(LINGY_CLOJURE_CORE): $(TMP_CLOJURE_CORE)
	perl tool/compile-clojure-core $< $(CLOJURE_CORE_SOURCE) > $@

$(TMP_CLOJURE_CORE):
	mkdir -p $(dir $@)
	curl -s $(CLOJURE_CORE_SOURCE) > $@
