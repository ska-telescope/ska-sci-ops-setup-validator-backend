# convenience include Makefile for core targets and variables

# Get the directory of this Makefile
# This is used to ensure that the release.mk file is included from the correct directory
MAKEFILE_DIR := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
BASE_YQ_VERSION ?= 4.43.1
BASE_YQ_INSTALL_DIR ?= /usr/local/bin

-include .make/release.mk
-include .make/docs.mk
-include .make/make.mk
-include .make/dev.mk
-include .make/help.mk
-include .make/metrics.mk

## TARGET: base-install-yq
## SYNOPSIS: make base-install-yq
## VARS:
##       BASE_YQ_VERSION=yq version to install - defaults to 4.43.1
##       BASE_YQ_INSTALL_DIR=directory for installing yq - defaults to /usr/local/bin.
##                           Only used if yq is not available in the current $PATH.
##                           This directory must be writable and part of $PATH.
##

base-install-yq:
	$(eval TMP_FILE:= $(shell mktemp))
	$(eval INSTALLED_YQ_VERSION := $(shell yq --version 2> /dev/null | awk '{print $$4}'))
	echo "INSTALLED_YQ_VERSION: $(INSTALLED_YQ_VERSION)"
	@if [ -z "$(INSTALLED_YQ_VERSION)" ]; then \
		echo "base-install-yq: Installing yq version $(BASE_YQ_VERSION) from https://github.com/mikefarah/yq/"; \
			if [ ! -d "$(BASE_YQ_INSTALL_DIR)" -o ! -w "$(BASE_YQ_INSTALL_DIR)" ]; then \
				echo "base-install-yq: BASE_YQ_INSTALL_DIR ($(BASE_YQ_INSTALL_DIR)) is not a writable directory."; \
				echo "base-install-yq: Please set BASE_YQ_INSTALL_DIR to a writable directory that is part of \$$PATH"; \
				exit 1; \
			fi; \
		curl -Lo $(TMP_FILE) https://github.com/mikefarah/yq/releases/download/v$(BASE_YQ_VERSION)/yq_linux_amd64 && \
		mv $(TMP_FILE) "$(BASE_YQ_INSTALL_DIR)/yq" && \
		chmod +x "$(BASE_YQ_INSTALL_DIR)/yq" && \
		if ! which yq &> /dev/null; then \
			echo "base-install-yq: Could not find the installed yq in \$$PATH."; \
			echo "base-install-yq: Please check if BASE_YQ_INSTALL_DIR ($(BASE_YQ_INSTALL_DIR)) is part of \$$PATH."; \
			exit 1; \
		fi \
	elif [ $(INSTALLED_YQ_VERSION) != v"$(BASE_YQ_VERSION)" ]; then \
		if which yq &> /dev/null; then \
			echo "base-install-yq: WARNING: yq already installed with version $(INSTALLED_YQ_VERSION) instead of target version $(BASE_YQ_VERSION)"; \
		fi \
	else \
		echo "base-install-yq: yq version $(BASE_YQ_VERSION) already installed"; \
	fi
