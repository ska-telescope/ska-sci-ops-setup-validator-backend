# include Makefile for make related targets and variables

# do not declare targets if help had been invoked
ifneq (long-help,$(firstword $(MAKECMDGOALS)))
ifneq (help,$(firstword $(MAKECMDGOALS)))

MAKE_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/.make-make-support

.PHONY: make submodule

## TARGET: make
## SYNOPSIS: make make
## HOOKS: none
## VARS: none
##  update the .make submodule containing the common Makefile targets and variables.

make:  ## Update the .make git submodule
	@. $(MAKE_SUPPORT); updateMake

## TARGET: update-make-and-commit
## SYNOPSIS: make update-make-and-commit
## HOOKS: none
## VARS: none
##  update the .make submodule and create a commit on the current branch using the Jira ticket in the branch name

update-make-and-commit:  ## Update the .make submodule and create a commit on the current branch
	@. $(MAKE_SUPPORT); updateMakeAndCommit


## TARGET: submodule
## SYNOPSIS: make submodule
## HOOKS: none
## VARS: none
##  Force initialisation and update of all git submodules in this project.

submodule:  ## update git submodules
	git submodule init
	git submodule update --recursive --remote
	git submodule update --init --recursive

# end of switch to suppress targets for help
endif
endif
