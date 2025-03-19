# include Makefile for docs (RTD) related targets and variables

# do not declare targets if help had been invoked
ifneq (long-help,$(firstword $(MAKECMDGOALS)))
ifneq (help,$(firstword $(MAKECMDGOALS)))

SHELL := /usr/bin/env bash
# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
DOCS_PYTHON_RUNNER ?= python3
DOCS_SPHINXOPTS    ?=## docs Sphinx opts
DOCS_SPHINXBUILD   ?= $(DOCS_PYTHON_RUNNER) -msphinx## Docs Sphinx build command
DOCS_SOURCEDIR     ?= docs/src## docs sphinx source directory
DOCS_BUILDDIR      ?= docs/build## docs sphinx build directory

DOCS_RTD_API_BASE_URL ?= https://readthedocs.org/api/v3
DOCS_RTD_PROJECT_SLUG ?= ska-telescope-$(CI_PROJECT_NAME)
DOCS_RTD_API_PROJECT_URL ?= $(DOCS_RTD_API_BASE_URL)/projects/$(DOCS_RTD_PROJECT_SLUG)
DOCS_RTD_PROJECT_MAIN_REF ?= latest
DOCS_RTD_PROJECT_REF ?= $(CI_COMMIT_REF_NAME)
DOCS_RTD_API_TOKEN ?=
DOCS_RTD_BUILD_SCRIPT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/resources/build_rtd_docs.py

ifeq ($(CI_COMMIT_REF_NAME),$(CI_DEFAULT_BRANCH))
  DOCS_RTD_PROJECT_REF := $(DOCS_RTD_PROJECT_MAIN_REF)
endif

ifeq ($(DOCS_RTD_PROJECT_REF),)
  DOCS_RTD_PROJECT_REF := $(DOCS_RTD_PROJECT_MAIN_REF)
endif

ifeq (docs-build,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "docs-build"
  DOCS_TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(DOCS_TARGET_ARGS):;@:)
endif

ifeq (docs-help,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "docs-help"
  DOCS_TARGET_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(DOCS_TARGET_ARGS):;@:)
endif

# Put it first so that "make" without argument is like "make help".
docs-help:  ## help for docs
	@$(DOCS_SPHINXBUILD) -M help $(DOCS_SOURCEDIR) $(DOCS_BUILDDIR) $(DOCS_SPHINXOPTS)

docs-pre-build:

docs-post-build:

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
# The target quickly fails if any of the builders fails
docs-do-build:
	mkdir -p $(DOCS_BUILDDIR)
	@set -e
	@for GOAL in $(DOCS_TARGET_ARGS); do \
    if [ "$$GOAL" = "rtd" ]; then \
      echo "docs-do-build: Running docs build using RTD"; \
      DOCS_RTD_API_TOKEN=$(DOCS_RTD_API_TOKEN) \
      DOCS_RTD_API_PROJECT_URL=$(DOCS_RTD_API_PROJECT_URL) \
      DOCS_RTD_PROJECT_REF=$(DOCS_RTD_PROJECT_REF) \
      $(DOCS_PYTHON_RUNNER) -u $(DOCS_RTD_BUILD_SCRIPT); \
    else \
      $(DOCS_SPHINXBUILD) -M $$GOAL $(DOCS_SOURCEDIR) $(DOCS_BUILDDIR) $(DOCS_SPHINXOPTS); \
    fi; \
	done

## TARGET: docs-build
## SYNOPSIS: make docs-build <sphinx command such as html|help|latex|clean|...>
## HOOKS: docs-pre-build, docs-post-build
## VARS:
##       DOCS_SOURCEDIR=<docs source directory> - default ./docs/src
##       DOCS_BUILDDIR=<docs build directory> - default ./docs/build
##       DOCS_SPHINXOPTS=<additional command line options for Sphinx>
##       DOCS_RTD_PROJECT_SLUG ?= <rtd project slug>
##       DOCS_RTD_PROJECT_MAIN_REF ?= <default/primary ref to build. stable or latest are suitable values>
##       DOCS_RTD_PROJECT_REF ?= <ref to build>
##
##  Build the RST documentation in the ./docs directory.

docs-build: docs-pre-build docs-do-build docs-post-build  ## Build docs - must pass sub command

.PHONY: docs-help docs-pre-build docs-do-build docs-post-build docs-build

# end of switch to suppress targets for help
endif
endif
