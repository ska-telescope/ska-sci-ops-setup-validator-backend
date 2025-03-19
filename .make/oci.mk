# include Makefile for OCI Image related targets and variables

.PHONY: metrics-collect-target
$(filter-out metrics-collect-target, $(MAKECMDGOALS)): metrics-collect-target

# do not declare targets if help had been invoked
ifneq (long-help,$(firstword $(MAKECMDGOALS)))
ifneq (help,$(firstword $(MAKECMDGOALS)))

ifeq ($(strip $(PROJECT_NAME)),)
  PROJECT_NAME=$(shell basename $(CURDIR))
endif

RELEASE_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/.make-release-support
OCI_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/.make-oci-support
OCI_IMAGE_SCRIPT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
OCI_NEXUS_REPO=docker-internal
OCI_HARBOR_REPO=staging

VERSION=$(shell . $(RELEASE_SUPPORT) ; RELEASE_CONTEXT_DIR=$(RELEASE_CONTEXT_DIR) setContextHelper; CONFIG=${CONFIG} setReleaseFile; getVersion)
TAG=$(shell . $(RELEASE_SUPPORT); RELEASE_CONTEXT_DIR=$(RELEASE_CONTEXT_DIR) setContextHelper; CONFIG=${CONFIG} setReleaseFile; getTag)

SHELL=/usr/bin/env bash

# User defined variables
CAR_OCI_REGISTRY_HOST ?=## OCI Image Registry
CAR_OCI_USE_HARBOR ?=true## Set to true to use Harbor instead of Nexus
OCI_VAULT_PKI_URI ?= ca@skao.int
VAULT_SERVER_URL ?= https://vault.skao.int/
VAULT_JWT_TOKEN ?=## JWT Token to login to vault

ifeq ($(strip $(CAR_OCI_REGISTRY_HOST)),)
ifneq ($(strip $(CAR_OCI_USE_HARBOR)),true)
CAR_OCI_REGISTRY_HOST = artefact.skao.int
else
CAR_OCI_REGISTRY_HOST = harbor.skao.int/staging
endif
# Only run if a OCI, Helm or K8s related target is included
ifneq ($(filter oci% helm% k8s%, $(MAKECMDGOALS)),)
$(warning Setting CAR_OCI_REGISTRY_HOST to `$(CAR_OCI_REGISTRY_HOST)`)
endif
endif

OCI_IMAGE_ROOT_DIR ?= images##Images root directory
OCI_IMAGE_BUILD_CONTEXT ?= .## Image build context directory, relative to ./$(OCI_IMAGE_ROOT_DIR)/<image dir> for multiple images, gets replaced by `$(PWD)` for single images where Dockerfile is in the root folder. Don't use `.` to provide root folder for multiple images, use `$(PWD)`.
OCI_IMAGE_FILE_PATH ?= Dockerfile## Image recipe file
# STS-104: /dev/null is needed to support CDPATH
ifneq ($(OCI_IMAGE_ROOT_DIR),images)
$(warning Using `$(OCI_IMAGE_ROOT_DIR)` as OCI_IMAGE_ROOT_DIR is supported but not recommended)
endif
OCI_IMAGE_DIRS := $(shell if [ -d $(OCI_IMAGE_ROOT_DIR) ]; then cd $(OCI_IMAGE_ROOT_DIR) > /dev/null; for name in $$(ls); do if [ -d $$name ]; then echo $$name; fi done else echo $(PROJECT_NAME);  fi;)
OCI_IMAGES ?= $(OCI_IMAGE_DIRS)## Images to lint and build
OCI_IMAGES_TO_PUBLISH ?= $(OCI_IMAGES)## Images to publish
OCI_IMAGE ?= $(PROJECT_NAME)## Default Image (from ./$(OCI_IMAGE_ROOT_DIR)/<OCI_IMAGE dir>)
OCI_BUILDER ?= docker## Image builder eg: docker, or podman
OCI_BUILD_ADDITIONAL_ARGS ?=## Additional build argument string
OCI_LINTER ?= hadolint/hadolint:v2.9.2
OCI_SKIP_PUSH ?=## OCI Skip the push (true/false)
OCI_TOOLS_IMAGE ?= artefact.skao.int/ska-tango-images-pytango-builder:9.3.12
OCI_BUILD_ADDITIONAL_TAGS ?=## Additional OCI tags to be built and published as part of build process. Note that: This won't affect publish jobs

.PHONY: oci-pre-build oci-image-build oci-post-build oci-build \
	oci-publish oci-pre-publish oci-do-publish oci-post-publish \
	oci-get-sign-cert oci-pre-get-sign-cert oci-do-get-sign-cert oci-post-get-sign-cert

oci-pre-lint:

oci-post-lint:

oci-image-lint:
	@. $(OCI_SUPPORT) ; \
	OCI_IMAGE_ROOT_DIR=$(OCI_IMAGE_ROOT_DIR) \
	OCI_BUILDER=$(OCI_BUILDER) \
	OCI_LINTER=$(OCI_LINTER) \
	OCI_IMAGE_FILE_PATH=$(OCI_IMAGE_FILE_PATH) \
	ociImageLint "$(OCI_IMAGES)"

## TARGET: oci-lint
## SYNOPSIS: make oci-lint
## HOOKS: oci-pre-lint, oci-post-lint
## VARS:
##       OCI_IMAGE_ROOT_DIR=<root dir of image directories>
##       OCI_BUILDER=[docker|podman] - OCI executor for linter
##       OCI_LINTER=<hadolint image> - OCI Image of linter application
##       OCI_IMAGE_FILE_PATH=<build file usually Dockerfile>
##       OCI_IMAGES=<list of image directories under ./$(OCI_IMAGE_ROOT_DIR)/>
##
##  Perform lint checks on a list of OCI Image build manifest files found
##  in the specified OCI_IMAGES directories.

oci-lint: oci-pre-lint oci-image-lint oci-post-lint  ## lint the OCI image

oci-pre-build:

oci-post-build:

oci-image-build: .release
	@echo "oci-image-build:Building image: $(OCI_IMAGE) registry: $(CAR_OCI_REGISTRY_HOST) context: $(OCI_IMAGE_BUILD_CONTEXT)"
	@. $(OCI_SUPPORT); \
	export OCI_IMAGE_BUILD_CONTEXT=$(OCI_IMAGE_BUILD_CONTEXT); \
	export OCI_IMAGE_FILE_PATH=$(OCI_IMAGE_ROOT_DIR)/$(strip $(OCI_IMAGE))/$(OCI_IMAGE_FILE_PATH); \
	if [[ -f Dockerfile ]]; then \
		echo "This is a oneshot OCI Image project with Dockerfile in the root OCI_IMAGE_BUILD_CONTEXT=$(PWD)"; \
		export OCI_IMAGE_BUILD_CONTEXT=$(PWD); \
		export OCI_IMAGE_FILE_PATH=$(OCI_IMAGE_FILE_PATH); \
	fi; \
	export VERSION=$(VERSION); \
	export TAG=$(TAG); \
	if [[ -f $(OCI_IMAGE_ROOT_DIR)/$(strip $(OCI_IMAGE))/.release ]]; then \
		echo "oci-image-build: Setting version from image's release file"; \
		. $(RELEASE_SUPPORT); RELEASE_CONTEXT_DIR="$(OCI_IMAGE_ROOT_DIR)/$(strip $(OCI_IMAGE))" setContextHelper; CONFIG=${CONFIG} setReleaseFile; \
		export VERSION=$$(getVersion); \
		export TAG=$$(getTag); \
	fi; \
	PROJECT_NAME=$(PROJECT_NAME) \
	CAR_OCI_REGISTRY_HOST=$(CAR_OCI_REGISTRY_HOST) \
	OCI_BUILDER=$(OCI_BUILDER) \
	OCI_IMAGE=$(strip $(OCI_IMAGE)) \
	OCI_IMAGE_ROOT_DIR=$(OCI_IMAGE_ROOT_DIR) \
	OCI_BUILD_ADDITIONAL_ARGS="$(OCI_BUILD_ADDITIONAL_ARGS) --build-arg http_proxy --build-arg https_proxy --build-arg CAR_OCI_REGISTRY_HOST=$(CAR_OCI_REGISTRY_HOST)" \
	OCI_BUILD_ADDITIONAL_TAGS="$(OCI_BUILD_ADDITIONAL_TAGS)" \
	OCI_SKIP_PUSH=$(OCI_SKIP_PUSH) \
	OCI_NEXUS_REPO=$(OCI_NEXUS_REPO) \
	OCI_HARBOR_REPO=$(OCI_HARBOR_REPO) \
	ociImageBuild "$(strip $(OCI_IMAGE))"

# default to skipping on the push if CI_JOB_ID is unset or 'local'
# as you cannot push to the repository without the CI pipeline credentials
# but let override in case of wanting to push to a local registry
ifeq ($(OCI_SKIP_PUSH),)
ifeq ($(CI_JOB_ID),)
OCI_SKIP_PUSH=true
else ifeq ($(CI_JOB_ID),local)
OCI_SKIP_PUSH=true
endif
endif

## TARGET: oci-build
## SYNOPSIS: make oci-build
## HOOKS: oci-pre-build, oci-post-build
## VARS:
##       OCI_IMAGE_ROOT_DIR=<root dir of image directories>
##       OCI_IMAGE=<image directory under ./$(OCI_IMAGE_ROOT_DIR)/> is the name of the image to build
##       OCI_IMAGE_BUILD_CONTEXT=<path to image build context> relative to ./$(OCI_IMAGE_ROOT_DIR)/<image dir> for multiple images, gets replaced by `$(PWD)` for single images where Dockerfile is in the root folder. Don't use `.` to provide root folder for multiple images, use `$(PWD)`.
##       OCI_IMAGE_FILE_PATH=<build file usually Dockerfile>
##       CAR_OCI_REGISTRY_HOST=<defaults to artefact.skao.int>
##       VERSION=<semver tag of image> - defaults to release key in .release file
##       RELEASE_CONTEXT_DIR=<directory holding .release file>
##       OCI_BUILDER=[docker|podman] - OCI executor for building images
##       OCI_BUILD_ADDITIONAL_ARGS=<any additional arguments to pass to OCI_BUILDER>
##       OCI_SKIP_PUSH=<set non-empty to skip push after build>
##       OCI_BUILD_ADDITIONAL_TAGS=<set as list of additional oci tags for build jobs> - defaults to empty
##
##  Perform an OCI Image build, and optionally push to the project GitLab registry
##  If a Dockerfile is found in the root of the project then the project is
##  deemed to be a one-shot image build with a OCI_IMAGE_BUILD_CONTEXT of the
##  entire project folder passed in. If there are multiple images under `$(OCI_IMAGE_ROOT_DIR)/` folder
##  OCI_IMAGE_BUILD_CONTEXT is set as the ./$(OCI_IMAGE_ROOT_DIR)/<image dir>.
##  A .dockerignore file should be placed in
##  the root of the project to limit the files/directories passed into the build
##  phase, as excess files can impact performance and have unintended consequences.
##  The image tag defaults to $VERSION-dev.c$CI_COMMIT_SHORT_SHA when pushing to $CI_REGISTRY
##  otherwise it will be $VERSION.
##  $VERSION is the current release key in the RELEASE_CONTEXT_DIR .release file.  The
##  RELEASE_CONTEXT_DIR defaults to the root folder of the project, but can be overriden
##  if .release files are required per image to build.  See ska-tango-images for an example.
##  When running oci-build inside the CI pipeline templates, CAR_OCI_REGISTRY_HOST is set to
##  ${CI_REGISTRY}/${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}, so that the image is automatically
##  pushed to the GitLab CI registry for the related project.

oci-build: oci-pre-build oci-image-build oci-post-build  ## build the OCI_IMAGE image (from /$(OCI_IMAGE_ROOT_DIR)/<OCI_IMAGE dir>)


oci-pre-build-all:

oci-post-build-all:

oci-do-build-all:
	$(foreach ociimage,$(OCI_IMAGES), make oci-build CAR_OCI_REGISTRY_HOST=$(CAR_OCI_REGISTRY_HOST) OCI_IMAGE=$(ociimage); rc=$$?; if [[ $$rc -ne 0 ]]; then exit $$rc; fi;)

## TARGET: oci-build-all
## SYNOPSIS: make oci-build-all
## HOOKS: oci-pre-build-all, oci-post-build-all
## VARS:
##       OCI_IMAGE_ROOT_DIR=<root dir of image directories>
##       OCI_IMAGES=<list of image directories under ./$(OCI_IMAGE_ROOT_DIR)/> names of the images to build
##       OCI_IMAGE_FILE_PATH=<build file usually Dockerfile>
##       CAR_OCI_REGISTRY_HOST=<defaults to artefact.skao.int>
##       OCI_BUILDER=[docker|podman] - OCI executor for building images
##       OCI_BUILD_ADDITIONAL_ARGS=<any additional arguments to pass to OCI_BUILDER>
##       OCI_SKIP_PUSH=<set non-empty to skip push after build>
##
##  Perform an OCI Image build for a list of images by iteratively calling oci-build - see above.

oci-build-all: oci-pre-build-all oci-do-build-all oci-post-build-all  ## build all the OCI_IMAGES image (from /$(OCI_IMAGE_ROOT_DIR)/*)

oci-pre-publish:

oci-post-publish:

oci-do-publish: CAR_OCI_REGISTRY_HOST:=$(if $(filter $(CAR_OCI_USE_HARBOR),true),harbor.skao.int/staging,artefact.skao.int)
oci-do-publish:
	@. $(OCI_SUPPORT) ; \
	echo CAR: $(CAR_OCI_REGISTRY_HOST); \
	export OCI_NEXUS_REPO=$(OCI_NEXUS_REPO); \
	export OCI_HARBOR_REPO=$(OCI_HARBOR_REPO); \
	export VERSION=$(VERSION); \
	if [[ -f $(OCI_IMAGE_ROOT_DIR)/$(strip $(OCI_IMAGE))/.release ]]; then \
		echo "oci-do-publish: Setting version from image's release file"; \
		. $(RELEASE_SUPPORT); RELEASE_CONTEXT_DIR="$(OCI_IMAGE_ROOT_DIR)/$(strip $(OCI_IMAGE))" setContextHelper; CONFIG=${CONFIG} setReleaseFile; \
		export VERSION=$$(getVersion); \
	fi; \
	echo "oci-do-publish: Checking for $(OCI_IMAGE) $${VERSION}"; \
	res=$$(CAR_OCI_REGISTRY_HOST=$(CAR_OCI_REGISTRY_HOST) OCI_NEXUS_REPO=$(OCI_NEXUS_REPO) OCI_HARBOR_REPO=$(OCI_HARBOR_REPO) ociImageExists "$(OCI_IMAGE)" "$${VERSION}"); \
	echo "oci-do-publish: Image check returned: $$res"; \
	if [[ "$$res" == "0" ]]; then \
		echo "oci-publish:WARNING: $(OCI_IMAGE):$${VERSION} already exists in OCI REGISTRY, skipping "; \
		exit 0; \
	else \
		echo "oci-do-publish: Pulling $${CI_REGISTRY}/$${CI_PROJECT_NAMESPACE}/$${CI_PROJECT_NAME}/$(OCI_IMAGE):$${VERSION}"; \
		$(OCI_BUILDER) pull $${CI_REGISTRY}/$${CI_PROJECT_NAMESPACE}/$${CI_PROJECT_NAME}/$(OCI_IMAGE):$${VERSION}; \
		$(OCI_BUILDER) tag $${CI_REGISTRY}/$${CI_PROJECT_NAMESPACE}/$${CI_PROJECT_NAME}/$(OCI_IMAGE):$${VERSION} $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE):$${VERSION}; \
		echo "oci-do-publish: Pushing to $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE):$${VERSION}"; \
		$(OCI_BUILDER) push $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE):$${VERSION}; \
		echo "oci-do-publish: Pushed to $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE):$${VERSION}"; \
		image_digest=$$($(OCI_BUILDER) inspect --format='{{index .RepoDigests 0}}' $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE):$${VERSION} | awk -F@ '{print $$2}'); \
		echo "oci-do-publish: Image digest: $$image_digest"; \
		curl https://cacerts.digicert.com/DigiCertTrustedRootG4.crt -o digicert_root_cert.crt; \
		notation sign --timestamp-url "http://timestamp.digicert.com" --timestamp-root-cert "digicert_root_cert.crt" $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE)@$$image_digest; \
	fi

## TARGET: oci-publish
## SYNOPSIS: make oci-publish
## HOOKS: oci-pre-publish, oci-post-publish
## VARS:
##       OCI_IMAGE_ROOT_DIR=<root dir of image directories>
##       OCI_IMAGES=<list of image directories under ./$(OCI_IMAGE_ROOT_DIR)/> names of the images to publish
##       CAR_OCI_REGISTRY_HOST=<defaults to artefact.skao.int>
##       OCI_BUILDER=[docker|podman] - OCI executor for publishing images
##       VERSION=<semver tag of image> - defaults to release key in .release file
##       RELEASE_CONTEXT_DIR=<directory holding .release file>
##
##  Publish a list of images to the CAR_OCI_REGISTRY_HOST.  This requires the source image to have
##  been already built and pushed to the ${CI_REGISTRY}.
##  The image to publish is pulled from:
##  ${CI_REGISTRY}/${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}/$(OCI_IMAGE):$(VERSION)
##  and tagged and pushed to:
##  ${CI_REGISTRY}/${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}/$(OCI_IMAGE):$(VERSION)

oci-publish: oci-pre-publish oci-do-publish oci-post-publish  ## publish the OCI_IMAGE to the CAR_OCI_REGISTRY_HOST registry from CI_REGISTRY

oci-pre-get-sign-cert:

oci-post-get-sign-cert:

oci-do-get-sign-cert:
	@. $(OCI_SUPPORT) ; \
	IssueOciImageSigningCert $(VAULT_SERVER_URL) $(VAULT_JWT_TOKEN) $(OCI_VAULT_PKI_URI)

#VAULT_TOKEN=$(vault write -address="$(VAULT_SERVER_URL)" auth/jwt/login -format=json role=oci-signing-pki jwt=$(VAULT_JWT_TOKEN) | jq -r '.auth.client_token'); \

## TARGET: oci-vault-pki
## SYNOPSIS: make oci-vault-pki
## HOOKS: oci-pre-vault-pki, oci-post-vault-pki
## VARS:
##       VAULT_SERVER_URL=<URL of the Vault server>
##       VAULT_JWT_TOKEN=<JWT obtained from OCI identity service>
##       OCI_VAULT_PKI_URI=<URI to identify the certificate>
##
##  Communicates with the Vault server to manage PKI operations for OCI image signing.
##  It sets up the environment to interact with Vault by exporting necessary variables.
##  Then, it obtains a client token from Vault using the provided JWT for authentication.
##  After obtaining the token, it requests a certificate from Vault for OCI image signing,
##  saving the private key and certificate chain to specific files.
##  Finally, it updates a configuration file with the paths to the generated private key and certificate files.

oci-get-sign-cert: oci-pre-get-sign-cert oci-do-get-sign-cert oci-post-get-sign-cert

oci-pre-publish-all:

oci-post-publish-all:

## TARGET: oci-publish-all
## SYNOPSIS: make oci-publish-all
## HOOKS: oci-pre-publish-all, oci-post-publish-all
## VARS:
##       OCI_IMAGE_ROOT_DIR=<root dir of image directories>
##       OCI_IMAGES_TO_PUBLISH=<image directories under ./$(OCI_IMAGE_ROOT_DIR)/> is the list of names of the images to publish
##       CAR_OCI_REGISTRY_HOST=<defaults to artefact.skao.int>
##       OCI_BUILDER=[docker|podman] - OCI executor for publishing images
##       OCI_SKIP_PUSH=<set non-empty to skip push after build>
##
##  Publish images listed in OCI_IMAGES_TO_PUBLISH to the CAR_OCI_REGISTRY_HOST by
##  iteratively calling oci-publish - see above.

oci-do-publish-all:
	$(foreach ociimage,$(OCI_IMAGES_TO_PUBLISH), make oci-publish OCI_IMAGE=$(ociimage); rc=$$?; if [[ $$rc -ne 0 ]]; then exit $$rc; fi;)

oci-publish-all: oci-pre-publish-all oci-do-publish-all oci-post-publish-all ## Publish all OCI Images in OCI_IMAGES_TO_PUBLISH

oci-pre-scan:

oci-post-scan:

oci-do-scan:
	@. $(OCI_SUPPORT) ; \
	export OCI_NEXUS_REPO=$(OCI_NEXUS_REPO); \
	export VERSION=$(VERSION); \
	if [[ -f $(OCI_IMAGE_ROOT_DIR)/$(strip $(OCI_IMAGE))/.release ]]; then \
		echo "oci-do-publish: Setting version from image's release file"; \
		. $(RELEASE_SUPPORT); RELEASE_CONTEXT_DIR="$(OCI_IMAGE_ROOT_DIR)/$(strip $(OCI_IMAGE))" setContextHelper; CONFIG=${CONFIG} setReleaseFile; \
		export VERSION=$$(getVersion); \
	fi; \
	echo "oci-do-scan: Checking for $(OCI_IMAGE) $${VERSION}"; \
	CAR_OCI_REGISTRY_HOST=$(CAR_OCI_REGISTRY_HOST) OCI_NEXUS_REPO=$(OCI_NEXUS_REPO)	OCI_HARBOR_REPO=$(OCI_HARBOR_REPO) ociImageScan "$(OCI_IMAGE)" "$${VERSION}"; \
	echo "oci-do-scan: Image scan returned: $$ocis_result"; \
	if [[ "$$ocis_result" == "0" ]]; then \
		echo "oci-scan:OK: $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE):$${VERSION} "; \
		exit 0; \
	else \
		echo "oci-do-scan: ERROR $(CAR_OCI_REGISTRY_HOST)/$(OCI_IMAGE):$${VERSION}"; \
		exit 1; \
	fi

## TARGET: oci-scan
## SYNOPSIS: make oci-scan
## HOOKS: oci-pre-scan, oci-post-scan
## VARS:
##       OCI_IMAGE_ROOT_DIR=<root dir of image directories>
##       OCI_IMAGE=<image name> is the image to be scanned by Trivy
##       CAR_OCI_REGISTRY_HOST=<defaults to artefact.skao.int> - registry where image held
##       VERSION=<semver tag of image> - defaults to release key in .release file
##       RELEASE_CONTEXT_DIR=<directory holding .release file>
##
##  Scan image OCI_IMAGE using Trivy.
##  iteratively calling oci-publish - see above.

oci-scan: oci-pre-scan oci-do-scan oci-post-scan  ## scan the OCI_IMAGE (must run inside docker.io/aquasec/trivy:latest)

oci-pre-scan-all:

oci-post-scan-all:

oci-do-scan-all:
	$(foreach ociimage,$(OCI_IMAGES_TO_PUBLISH), make oci-scan OCI_IMAGE=$(ociimage); rc=$$?; if [[ $$rc -ne 0 ]]; then exit $$rc; fi;)

## TARGET: oci-scan-all
## SYNOPSIS: make oci-scan-all
## HOOKS: oci-pre-scan-all, oci-post-scan-all
## VARS:
##       OCI_IMAGE_ROOT_DIR=<root dir of image directories>
##       OCI_IMAGES_TO_PUBLISH=<image directories under ./$(OCI_IMAGE_ROOT_DIR)/> is the list of names of the images to be scanned by Trivy
##       CAR_OCI_REGISTRY_HOST=<defaults to artefact.skao.int> - registry where image held
##
##  Scan image OCI_IMAGE using Trivy.
##  iteratively calling oci-publish - see above.

oci-scan-all: oci-pre-scan-all oci-do-scan-all oci-post-scan-all ## Scan all OCI Images in OCI_IMAGES_TO_PUBLISH (must run inside docker.io/aquasec/trivy:latest)

## TARGET: oci-boot-into-tools
## SYNOPSIS: make oci-boot-into-tools
## HOOKS: none
## VARS:
##       OCI_BUILDER=[docker|podman] - OCI container executor
##       OCI_TOOLS_IMAGE=<OCI Tools Image> - tools image - default artefact.skao.int/ska-tango-images-pytango-builder
##
##  Launch the tools image with the current directory mounted at /app in container and
##  install the current requirements.txt .

oci-boot-into-tools: ## Boot the pytango-builder image with the project directory mounted to /app
	$(OCI_BUILDER) run --rm -ti --volume $(pwd):/app $(OCI_TOOLS_IMAGE) bash -c \
	'pip3 install black pylint-junit; if [[ -f "requirements-dev.txt" ]]; then pip3 install -r requirements-dev.txt; else if [[ -f "requirements.txt" ]]; then pip3 install -r requirements.txt; fi; fi; bash'

# end of switch to suppress targets for help
endif
endif
