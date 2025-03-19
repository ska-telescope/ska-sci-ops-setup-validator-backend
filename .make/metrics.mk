METRICS_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/.make-metrics-support

METRICS_ENDPOINT ?= http://host.docker.internal:8000
MAKE_VERSION := $(shell make --version | head -n 1)

# Feature flags and debug options
METRICS_ENABLED ?= true
METRICS_DEBUG ?= false
METRICS_CURL_DEBUG_OPTS ?= "-v --trace-ascii /dev/stderr"

# Curl options
METRICS_CURL_OPTIONS ?= "--connect-timeout 3 --max-time 10 --retry 3 --retry-delay 1"

ifeq ($(METRICS_ENABLED),true)

ifneq ($(CI_JOB_ID),)

define METRICS_PIPELINE_BODY
{"REPOSITORY_INFORMATION":{"CI_PROJECT_TITLE":"$(CI_PROJECT_TITLE)","CI_PROJECT_PATH":"$(CI_PROJECT_PATH)","CI_COMMIT_BRANCH":"$(CI_COMMIT_BRANCH)","CI_COMMIT_SHORT_SHA":"$(CI_COMMIT_SHORT_SHA)"},"PIPELINE_INFORMATION":{"CI_PIPELINE_CREATED_AT":"$(CI_PIPELINE_CREATED_AT)","CI_PIPELINE_ID":"$(CI_PIPELINE_ID)","CI_PIPELINE_SOURCE":"$(CI_PIPELINE_SOURCE)","CI_PIPELINE_URL":"$(CI_PIPELINE_URL)"},"USER_INFORMATION":{"GITLAB_USER_EMAIL":"$(GITLAB_USER_EMAIL)"}}
endef
export METRICS_PIPELINE_BODY

define METRICS_JOB_BODY
{"CI_PIPELINE_ID":"$(CI_PIPELINE_ID)","CI_JOB_ID":"$(CI_JOB_ID)","CI_JOB_IMAGE":"$(CI_JOB_IMAGE)","CI_JOB_NAME":"$(CI_JOB_NAME)","CI_JOB_STAGE":"$(CI_JOB_STAGE)","CI_JOB_STARTED_AT":"$(CI_JOB_STARTED_AT)","CI_RUNNER_ID":"$(CI_RUNNER_ID)","CI_RUNNER_TAGS":$(CI_RUNNER_TAGS),"CI_RUNNER_VERSION":"$(CI_RUNNER_VERSION)","MAKE_VERSION":"$(MAKE_VERSION)"}
endef
export METRICS_JOB_BODY

define METRICS_TARGET_BODY
{"CI_PIPELINE_ID":"$(CI_PIPELINE_ID)","CI_JOB_ID":"$(CI_JOB_ID)","MAKE_TARGET":"$(MAKECMDGOALS)","CI_PROJECT_ID":"$(CI_PROJECT_ID)","CI_PROJECT_NAME":"$(CI_PROJECT_NAME)"}
endef
export METRICS_TARGET_BODY

## TARGET: metrics-collect-target
## SYNOPSIS: make metrics-collect-target
## HOOKS: none
## VARS:
##       METRICS_ENDPOINT=<URL of the metrics collection endpoint>
##       METRICS_ENABLED=<true or false>. Enable or disable metrics collection. Default true.
##       METRICS_DEBUG=<true or false>. Enable or disable debug output for curl. Default false.
##       CURL_DEBUG_OPTS=<curl debug options>. Custom debug options for curl. Default "-v --trace-ascii /dev/stderr"
##       METRICS_CURL_OPTIONS=<curl options>. Custom options for curl. Default "--max-time 5 --retry 3 --retry-delay 1 --connect-timeout 3"
##
##  Collect and send target metrics to the specified endpoint.
##  Metrics collection is only performed if METRICS_ENABLED is true and CI_JOB_ID is set.

metrics-collect-target:
	@. $(METRICS_SUPPORT); push_metrics $(METRICS_ENDPOINT)/target '$(METRICS_TARGET_BODY)' > /dev/null 2>&1 &

## TARGET: metrics-collect-job
## SYNOPSIS: make metrics-collect-job
## HOOKS: none
## VARS:
##       METRICS_ENDPOINT=<URL of the metrics collection endpoint>
##       METRICS_ENABLED=<true or false>. Enable or disable metrics collection. Default true.
##       METRICS_DEBUG=<true or false>. Enable or disable debug output for curl. Default false.
##       CURL_DEBUG_OPTS=<curl debug options>. Custom debug options for curl. Default "-v --trace-ascii /dev/stderr"
##       METRICS_CURL_OPTIONS=<curl options>. Custom options for curl. Default "--max-time 5 --retry 3 --retry-delay 1 --connect-timeout 3"
##
##  Collect and send job metrics to the specified endpoint.
##  Metrics collection is only performed if METRICS_ENABLED is true and CI_JOB_ID is set.

metrics-collect-job:
	@. $(METRICS_SUPPORT); push_metrics $(METRICS_ENDPOINT)/job '$(METRICS_JOB_BODY)' > /dev/null 2>&1 &

## TARGET: metrics-collect-pipeline
## SYNOPSIS: make metrics-collect-pipeline
## HOOKS: none
## VARS:
##       METRICS_ENDPOINT=<URL of the metrics collection endpoint>
##       METRICS_ENABLED=<true or false>. Enable or disable metrics collection. Default true.
##       METRICS_DEBUG=<true or false>. Enable or disable debug output for curl. Default false.
##       CURL_DEBUG_OPTS=<curl debug options>. Custom debug options for curl. Default "-v --trace-ascii /dev/stderr"
##       METRICS_CURL_OPTIONS=<curl options>. Custom options for curl. Default "--max-time 5 --retry 3 --retry-delay 1 --connect-timeout 3"
##
##  Collect and send pipeline metrics to the specified endpoint.
##  Metrics collection is only performed if METRICS_ENABLED is true and CI_JOB_ID is set.

metrics-collect-pipeline:
	@. $(METRICS_SUPPORT); push_metrics $(METRICS_ENDPOINT)/pipeline '$(METRICS_PIPELINE_BODY)' > /dev/null 2>&1 &

endif

endif