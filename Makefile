# include OCI Images support
include .make/oci.mk

# include k8s support
include .make/k8s.mk

# include Helm Chart support
include .make/helm.mk

# Include Python support
include .make/python.mk

# include raw support
include .make/raw.mk

# include core make support
include .make/base.mk

# Override the defualt image repository and tag to always use the previously built image in pipelines
ifneq ($(CI_JOB_ID),)
K8S_CHART_PARAMS = --set image.tag=$(VERSION)-dev.c$(CI_COMMIT_SHORT_SHA) \
 --set image.repository=$(CI_REGISTRY)/ska-telescope/ska-sci-ops-setup-validator-backend
endif
