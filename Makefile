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

# unset defaults so settings in pyproject.toml take effect
PYTHON_LINE_LENGTH = 88
PYTHON_SWITCHES_FOR_BLACK =
PYTHON_SWITCHES_FOR_ISORT =

# Disable warning, convention, and refactoring messages
# Disable errors:
PYTHON_SWITCHES_FOR_FLAKE8=--ignore=A003,FS001,FS002,FS003,T101,W503,W391,E266,E402,E501,E731,F401,F541,F841,RST210,BLK100,E203
PYTHON_SWITCHES_FOR_PYLINT=--disable=C,R,W,E
