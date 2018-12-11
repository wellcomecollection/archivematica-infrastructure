##############################################################################
#
# This is a copy of `terraform.Makefile`, the main copy of which is in the
# wellcometrust/platform repo.
#
# If you need to make changes: edit that, and copy the changes here.
#
##############################################################################

TERRAFORM_WRAPPER_IMAGE = wellcome/terraform_wrapper:13


# This one liner gives us the version of terraform running in our
# terraform_wrapper container.
ifndef TF_VERSION
TF_VERSION = $(shell docker inspect wellcome/terraform_wrapper:13 | grep 'com.hashicorp.terraform.version' | head -n 1 | tr '"' ' ' | awk '{print $$3}')
endif


ifndef UPTODATE_GIT_DEFINED

# This target checks if you're up-to-date with the current master.
# This avoids problems where Terraform goes backwards or breaks
# already-applied changes.
#
# Consider the following scenario:
#
#     * --- * --- X --- Z                 master
#                  \
#                   Y --- Y --- Y         feature branch
#
# We cut a feature branch at X, then applied commits Y.  Meanwhile master
# added commit Z, and ran `terraform apply`.  If we run `terraform apply` on
# the feature branch, this would revert the changes in Z!  We'd rather the
# branches looked like this:
#
#     * --- * --- X --- Z                 master
#                        \
#                         Y --- Y --- Y   feature branch
#
# So that the commits in the feature branch don't unintentionally revert Z.
#
uptodate-git:
	@git fetch origin
	@if ! git merge-base --is-ancestor origin/master HEAD; then \
		echo "You need to be up-to-date with master before you can continue!"; \
		exit 1; \
	fi

UPTODATE_GIT_DEFINED = true

endif


# Run a 'terraform plan' step.
#
# Args:
#   $1 - Path to the Terraform directory.
#	$2 - true/false: is this a public-facing stack?
#
define terraform_plan
	make uptodate-git
	$(ROOT)/docker_run.py --aws -- \
		--volume $(ROOT):$(ROOT) \
		--workdir $(ROOT)/$(1) \
		--env OP=plan \
		--env GET_TFVARS=true \
		--env BUCKET_NAME=$(TFVARS_BUCKET) \
		--env OBJECT_KEY=$(TFVARS_KEY) \
		--env IS_PUBLIC_FACING=$(2) \
		$(TERRAFORM_WRAPPER_IMAGE)
endef


# Run a 'terraform apply' step.
#
# Args:
#   $1 - Path to the Terraform directory.
#
define terraform_apply
	make uptodate-git
	$(ROOT)/docker_run.py --aws -- \
		--volume $(ROOT):$(ROOT) \
		--workdir $(ROOT)/$(1) \
		--env BUCKET_NAME=$(TFPLAN_BUCKET) \
		--env OP=apply \
		$(TERRAFORM_WRAPPER_IMAGE)
endef


# These are a pair of dodgy hacks to allow us to run something like:
#
#	$ make stack-terraform-import aws_s3_bucket.bucket my-bucket-name
#
#	$ make stack-terraform-state-rm aws_s3_bucket.bucket
#
# In practice it slightly breaks the conventions of Make (you're not meant to
# read command-line arguments), but since this is only for one-offs I think
# it's okay.
#
# This is slightly easier than using terraform on the command line, as paths
# are different in/outside Docker, so you have to reload all your modules,
# which is slow and boring.
#
define terraform_import
	$(ROOT)/docker_run.py --aws -- \
		--volume $(ROOT):$(ROOT) \
		--workdir $(ROOT)/$(2) \
		hashicorp/terraform:$(TF_VERSION) import $(filter-out $(1)-terraform-import,$(MAKECMDGOALS))
endef


define terraform_state_rm
	$(ROOT)/docker_run.py --aws -- \
		--volume $(ROOT):$(ROOT) \
		--workdir $(ROOT)/$(2) \
		hashicorp/terraform:$(TF_VERSION) state rm $(filter-out $(1)-terraform-state-rm,$(MAKECMDGOALS))
endef


# Define a series of Make tasks (plan, apply) for a Terraform stack.
#
# Args:
#	$1 - Name of the stack.
#	$2 - Root to the Terraform directory.
#	$3 - Is this a public-facing stack?  (true/false)
#
define terraform_target_template
$(1)-terraform-plan:
	$(call terraform_plan,$(2),$(3))

$(1)-terraform-apply:
	$(call terraform_apply,$(2))

$(1)-terraform-import:
	$(call terraform_import,$(1),$(2))

$(1)-terraform-state-rm:
	$(call terraform_state_rm,$(1),$(2))
endef
