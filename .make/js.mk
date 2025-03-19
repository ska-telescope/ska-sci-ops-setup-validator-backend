# include Makefile for Javascript related targets and variables

.PHONY: metrics-collect-target
$(filter-out metrics-collect-target, $(MAKECMDGOALS)): metrics-collect-target

# do not declare targets if help had been invoked
ifneq (long-help,$(firstword $(MAKECMDGOALS)))
ifneq (help,$(firstword $(MAKECMDGOALS)))

ifeq ($(strip $(PROJECT)),)
  NAME=$(shell basename $(CURDIR))
else
  NAME=$(PROJECT)
endif

JS_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/.make-js-support
JS_PROJECT_BASE_DIR := $(shell dirname $$(dirname $(abspath $(lastword $(MAKEFILE_LIST)))))
VERSION=$(shell . $(RELEASE_SUPPORT) ; RELEASE_CONTEXT_DIR=$(RELEASE_CONTEXT_DIR) setContextHelper; CONFIG=${CONFIG} setReleaseFile; getVersion)
TAG=$(shell . $(RELEASE_SUPPORT); RELEASE_CONTEXT_DIR=$(RELEASE_CONTEXT_DIR) setContextHelper; CONFIG=${CONFIG} setReleaseFile; getTag)

SHELL=/usr/bin/env bash

JS_PROJECT_DIR ?= .## JS project root dir
# Remove trailing slashes
JS_PROJECT_DIR := $(patsubst %/,%,$(strip $(JS_PROJECT_DIR)))
ifeq ($(JS_PROJECT_DIR),)
JS_PROJECT_DIR := .
$(warning 'JS_PROJECT_DIR' not set, setting to '.')
endif

JS_SRC ?= src## JS src directory - defaults to src

JS_COMMAND_RUNNER ?= npx## use to specify command runner, e.g. "npx" or "nothing"

JS_ESLINT_CONFIG ?= .eslintrc.js## use to specify the file to configure eslint, e.g. ".eslintrc.json"

JS_ESLINT_FILE_EXTENSIONS ?= js,jsx,ts,tsx## used to specify which extensions to use with eslint

JS_VARS_BEFORE_ESLINT_FORMAT ?= ## used to include needed argument variables to pass to eslint for format

JS_SWITCHES_FOR_ESLINT_FORMAT ?= ## Custom switches added to eslint for format

JS_VARS_BEFORE_ESLINT_LINT ?= ## used to include needed argument variables to pass to eslint for linting

JS_SWITCHES_FOR_ESLINT_LINT ?= ## Custom switches added to eslint for linting

JS_PACKAGE_MANAGER ?= yarn## use to specify package manager runner, e.g. "yarn" or "npm"

JS_SWITCHES_FOR_INSTALL ?= ## switches to pass to install command

# Default unit testing platform - jest

## Because taranta projects clone the upstream projects shared with MaxIV, the actual directory is not the "root" directory
## The post-processing jobs look for the 'build' directory at the root of the project
JS_BUILD_REPORTS_DIRECTORY ?= $(JS_PROJECT_BASE_DIR)/build/reports## build reports directory
JS_E2E_BUILD_TESTS_DIRECTORY ?= $(JS_PROJECT_BASE_DIR)/build/tests## build tests directory for e2e tests

JS_VARS_BEFORE_TEST ?= ## used to include needed argument variables to pass to start command before test

JS_TEST_COMMAND ?= jest## command to use to run jest tests (i.e, react-scripts test)

JS_TEST_SWITCHES ?= ##Custom switches to pass to jest

## switches to pass jest tests
JS_TEST_DEFAULT_SWITCHES ?= --ci --env=jsdom --watchAll=false --passWithNoTests \
	--verbose --reporters=default --reporters=jest-junit \
	--coverage --coverageDirectory=$(JS_BUILD_REPORTS_DIRECTORY) \
	--coverageReporters=text --coverageReporters=cobertura --coverageReporters=html \
	--logHeapUsage $(JS_TEST_SWITCHES)

JS_E2E_TESTS_DIR ?= tests/cypress##directory where to look for e2e tests

KUBE_HOST ?= https://k8s.stfc.skao.int
JS_E2E_TEST_BASE_URL ?= $(KUBE_HOST)/$(KUBE_NAMESPACE)## default URL for application when running e2e tests

JS_E2E_VARS_BEFORE_TEST ?= ## used to include needed argument variables to pass to start command before cypress

JS_E2E_TEST_COMMAND ?= cypress run## command to use to start the cypress tests (i.e, react-scripts test)

JS_E2E_TEST_SWITCHES ?= ##Custom switches to pass to cypress

## switches to pass to cypress
JS_E2E_TEST_DEFAULT_SWITCHES ?= --e2e --headless --reporter junit --reporter-options \
	"mochaFile=$(JS_E2E_BUILD_TESTS_DIRECTORY)/e2e-tests-[hash].xml" --config baseUrl=$(JS_E2E_TEST_BASE_URL) \
	$(JS_E2E_TEST_SWITCHES)

JS_E2E_COVERAGE_ENABLED ?= true## enable or disable execution of coverage command, given if test command produces or not coverage report

JS_E2E_COVERAGE_COMMAND ?= nyc report## command to use to generate coverage reports

JS_E2E_VARS_BEFORE_COVERAGE ?= ## used to include needed argument variables to pass to start command before nyc

JS_E2E_COVERAGE_SWITCHES ?= ##Custom switches to pass to nyc

## switches to pass to nyc
JS_E2E_COVERAGE_DEFAULT_SWITCHES ?= --report-dir $(JS_BUILD_REPORTS_DIRECTORY) \
	--reporter html --reporter cobertura --reporter text \
	$(JS_E2E_COVERAGE_SWITCHES)

## Taranta uses NPM while skeleton based projects use YARN
## Quickly define the "best-practice" arguments for each package manager
ifeq ($(JS_SWITCHES_FOR_INSTALL),)
ifneq (,$(findstring npm,$(VARIABLE)))
    JS_SWITCHES_FOR_INSTALL = --no-cache
endif
ifneq (,$(findstring yarn,$(VARIABLE)))
    JS_SWITCHES_FOR_INSTALL = --frozen-lockfile
endif
endif

js-pre-install:

js-post-install:

js-do-install:
	@cd $(JS_PROJECT_DIR); \
	if [ ! -d "./node_modules" ]; then \
		$(JS_PACKAGE_MANAGER) install $(JS_SWITCHES_FOR_INSTALL); \
	else \
		echo "js-do-install: '$(JS_PROJECT_DIR)/node_modules' already exists. If you want to re-install, run 'make js-install-reinstall'"; \
	fi

## TARGET: js-install
## SYNOPSIS: make js-install
## HOOKS: js-pre-install, js-post-install
## VARS:
##       JS_PACKAGE_MANAGER=<package manager executor> - defaults to yarn
##       JS_SWITCHES_FOR_INSTALL=<switches for install command>
##
##  Install JS project dependencies

js-install: js-pre-install js-do-install js-post-install

js-install-clean:
	@echo "js-install-clean: Removing '$(JS_PROJECT_DIR)/node_modules'"
	@cd $(JS_PROJECT_DIR); \
	rm -rf ./node_modules

## TARGET: js-install-clean
## SYNOPSIS: make js-install-clean
## HOOKS:
## VARS:
##
##  Clean JS project dependencies

js-install-reinstall: js-install-clean js-install

## TARGET: js-install-reinstall
## SYNOPSIS: make js-install-reinstall
## HOOKS:
## VARS:
##
##  Cleanly reinstall JS project dependencies

.PHONY:	js-install js-pre-install js-do-install js-post-install js-install-clean js-install-reinstall

js-pre-format:

js-post-format:

js-do-format:
	@cd $(JS_PROJECT_DIR); \
	$(JS_VARS_BEFORE_ESLINT_FORMAT) $(JS_COMMAND_RUNNER) eslint -c $(JS_ESLINT_CONFIG) \
		--fix --color $(JS_SWITCHES_FOR_ESLINT_FORMAT) \
		--ignore-pattern "**/node_modules/*" --ignore-pattern "**/.eslintignore" \
		"$(JS_SRC)/**/*.{$(JS_ESLINT_FILE_EXTENSIONS)}"

## TARGET: js-format
## SYNOPSIS: make js-format
## HOOKS: js-pre-format, js-post-format
## VARS:
##		JS_SRC=<file or directory path to JS code> - default 'src/'
##		JS_COMMAND_RUNNER=<command executor> - defaults to npx
##		JS_ESLINT_CONFIG=<path to eslint config file> - defaults to .eslintrc.js
##		JS_ESLINT_FILE_EXTENSIONS=<file extensions> - defaults to js,jsx,ts,tsx
##		JS_VARS_BEFORE_ESLINT_FORMAT=<environment variables to pass to eslint>
##		JS_SWITCHES_FOR_ESLINT_FORMAT=<switches to pass to eslint>
##
##  Reformat project javascript code in the given directories/files using eslint

js-format: js-install js-pre-format js-do-format js-post-format  ## format the js code

.PHONY:	js-format js-pre-format js-do-format js-post-format

js-pre-lint:

js-post-lint:

js-do-lint:
	@cd $(JS_PROJECT_DIR); \
	mkdir -p $(JS_BUILD_REPORTS_DIRECTORY); \
	$(JS_PACKAGE_MANAGER) list --depth=0 --json > $(JS_BUILD_REPORTS_DIRECTORY)/dependencies.json; \
	$(JS_PACKAGE_MANAGER) list --depth=0  > $(JS_BUILD_REPORTS_DIRECTORY)/dependencies.txt; \
	$(JS_VARS_BEFORE_ESLINT_LINT) $(JS_COMMAND_RUNNER) eslint -c $(JS_ESLINT_CONFIG) \
		--fix-dry-run --color $(JS_SWITCHES_FOR_ESLINT_LINT) \
		--ignore-pattern "**/node_modules/*" --ignore-pattern "**/.eslintignore" \
		"$(JS_SRC)/**/*.{$(JS_ESLINT_FILE_EXTENSIONS)}"; \
	$(JS_VARS_BEFORE_ESLINT_LINT) $(JS_COMMAND_RUNNER) eslint -c $(JS_ESLINT_CONFIG) \
		--ignore-pattern "**/node_modules/*" --ignore-pattern "**/.eslintignore" \
		-f junit -o $(JS_BUILD_REPORTS_DIRECTORY)/linting.xml $(JS_SWITCHES_FOR_ESLINT_LINT) \
		"$(JS_SRC)/**/*.{$(JS_ESLINT_FILE_EXTENSIONS)}"


## TARGET: js-lint
## SYNOPSIS: make js-lint
## HOOKS: js-pre-lint, js-post-lint
## VARS:
##
##		JS_SRC=<file or directory path to JS code> - default 'src/'
##		JS_BUILD_REPORTS_DIRECTORY=<directory to store build and test results>
##		JS_COMMAND_RUNNER=<command executor> - defaults to npx
##		JS_PACKAGE_MANAGER=<package manager to use> - defaults to yarn
##		JS_ESLINT_FILE_EXTENSIONS=<file extensions> - defaults to js,jsx,ts,tsx
##		JS_VARS_BEFORE_ESLINT_LINT=<environment variables to pass to eslint>
##		JS_SWITCHES_FOR_ESLINT_LINT=<switches to pass to eslint>
##
##  Lint check javascript code in the given directories/files using eslint

js-lint: js-install js-pre-lint js-do-lint js-post-lint  ## lint the javascript code

.PHONY:	js-lint js-pre-lint js-do-lint js-post-lint

js-pre-audit:

js-post-audit:

js-do-audit:
	$(JS_PACKAGE_MANAGER) audit $(JS_SWITCHES_FOR_AUDIT);

## TARGET: js-audit
## SYNOPSIS: make js-audit
## HOOKS: js-pre-audit, js-post-audit
## VARS:
##       JS_PACKAGE_MANAGER=<package manager executor> - defaults to yarn
##       JS_SWITCHES_FOR_AUDIT=<switches for install command>
##
##  Check project dependencies for vulnerabilities

js-audit: js-pre-audit js-do-audit js-post-audit  ## check project dependencies for vulnerabilities

js-pre-test:

js-post-test:

js-do-test:
	@{ \
		cd $(JS_PROJECT_DIR); \
		mkdir -p $(JS_BUILD_REPORTS_DIRECTORY); \
		export JEST_JUNIT_OUTPUT_DIR=$(JS_BUILD_REPORTS_DIRECTORY); \
		export JEST_JUNIT_OUTPUT_NAME=unit-tests.xml; \
		$(JS_VARS_BEFORE_TEST) $(JS_COMMAND_RUNNER) $(JS_TEST_COMMAND) $(JS_TEST_DEFAULT_SWITCHES); \
		EXIT_CODE=$$?; \
		echo "js-do-test: Exit code $${EXIT_CODE}"; \
		cp $(JS_BUILD_REPORTS_DIRECTORY)/cobertura-coverage.xml $(JS_BUILD_REPORTS_DIRECTORY)/code-coverage.xml; \
		exit $$EXIT_CODE; \
	}

## TARGET: js-test
## SYNOPSIS: make js-test
## HOOKS: js-pre-test, js-post-test
## VARS:
##		JS_SRC=<file or directory path to JS code> - default 'src/'
##		JS_BUILD_REPORTS_DIRECTORY=<directory to store build and test results>
##		JS_COMMAND_RUNNER=<command executor> - defaults to npx
##		JS_TEST_COMMAND=<command to invoke tests> - defaults to jest
##		JS_TEST_SWITCHES=<extra switches to pass to test command>
##		JS_TEST_DEFAULT_SWITCHES=<default switches plus extra to pass to test command>
##
##  Run javascript unit tests using jest

js-test: js-install js-pre-test js-do-test js-post-test  ## test the javascript code

.PHONY:	js-test js-pre-test js-do-test js-post-test

js-pre-e2e-test:

js-post-e2e-test:

js-do-e2e-test:
	@if [ ! -d "$(JS_E2E_TESTS_DIR)" ]; then \
		echo "js-do-e2e-test: No tests found"; \
		exit 0; \
	fi
	@{ \
		. $(JS_SUPPORT); \
		cd $(JS_PROJECT_DIR); \
		mkdir -p $(JS_BUILD_REPORTS_DIRECTORY); \
		mkdir -p $(JS_E2E_BUILD_TESTS_DIRECTORY); \
		rm -rf $(JS_E2E_BUILD_TESTS_DIRECTORY)/e2e*.xml; \
		$(JS_E2E_VARS_BEFORE_TEST) COVERAGE_OUTPUT_DIR=$(JS_E2E_BUILD_TESTS_DIRECTORY) $(JS_COMMAND_RUNNER) $(JS_E2E_TEST_COMMAND) $(JS_E2E_TEST_DEFAULT_SWITCHES); \
		EXIT_CODE=$$?; \
		echo "js-do-e2e-test: Exit code $${EXIT_CODE}"; \
		JS_COMMAND_RUNNER=$(JS_COMMAND_RUNNER) jsMergeReports $(JS_BUILD_REPORTS_DIRECTORY)/e2e-tests.xml "$(JS_E2E_BUILD_TESTS_DIRECTORY)/e2e*.xml"; \
		if [ "$(JS_E2E_COVERAGE_ENABLED)" == "true" ]; then \
			$(JS_E2E_VARS_BEFORE_COVERAGE) COVERAGE_OUTPUT_DIR=$(JS_E2E_BUILD_TESTS_DIRECTORY) $(JS_COMMAND_RUNNER) $(JS_E2E_COVERAGE_COMMAND) $(JS_E2E_COVERAGE_DEFAULT_SWITCHES); \
			cp $(JS_E2E_BUILD_TESTS_DIRECTORY)/cobertura-coverage.xml $(JS_BUILD_REPORTS_DIRECTORY)/e2e-coverage.xml; \
		fi; \
		exit $$EXIT_CODE; \
	}


## TARGET: js-e2e-test
## SYNOPSIS: make js-e2e-test
## HOOKS: js-pre-e2e-test, js-post-e2e-test
## VARS:
##		JS_SRC=<file or directory path to JS code> - default 'src/'
##		JS_BUILD_REPORTS_DIRECTORY=<directory to store build and test results>
##		JS_COMMAND_RUNNER=<command executor> - defaults to npx
##		JS_E2E_BUILD_TESTS_DIRECTORY=<directory to store individual e2e test reports>
##		JS_E2E_TESTS_DIR=<path to location of e2e tests> - defaults to 'tests/cypress/'
##		JS_E2E_VARS_BEFORE_TEST=<vars before e2e test command>
##		JS_E2E_TEST_COMMAND=<command to invoke e2e tests> - defaults to cypress
##		JS_E2E_COVERAGE_ENABLED=<boolean flag for including coverage report> - defaults to true
##		JS_E2E_TEST_SWITCHES=<extra switches to pass to test command>
##		JS_E2E_TEST_DEFAULT_SWITCHES=<default switches plus extra to pass to test command>
##
##  Run javascript e2e tests using cypress

js-e2e-test: js-pre-e2e-test js-do-e2e-test js-post-e2e-test  ## e2e test the javascript code

.PHONY:	js-e2e-test js-pre-e2e-test js-do-e2e-test js-post-e2e-test

# end of switch to suppress targets for help
endif
endif
