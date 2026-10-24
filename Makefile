# agent-cpp developer entry points. Run `make help` for the target list.
SHELL := /bin/sh
PROJECT_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
MAKEFLAGS += --no-builtin-rules --no-print-directory
.SUFFIXES:
# Gates share build trees; their steps run in order.
.NOTPARALLEL:

include $(PROJECT_ROOT)/make/config.mk
include $(PROJECT_ROOT)/make/build.mk
include $(PROJECT_ROOT)/make/dist.mk
include $(PROJECT_ROOT)/make/quality.mk
include $(PROJECT_ROOT)/make/env.mk

.DEFAULT_GOAL := help

##@ General
.PHONY: help
help: ## List available targets
	@awk -f "$(PROJECT_ROOT)/make/help.awk" $(MAKEFILE_LIST)
