ROOT = $(shell git rev-parse --show-toplevel)

export INFRA_BUCKET = wellcomecollection-workflow-infra

export TFVARS_BUCKET = $(INFRA_BUCKET)
export TFVARS_KEY    = terraform/workflow.tfvars
export TFPLAN_BUCKET = $(INFRA_BUCKET)

include $(ROOT)/makefiles/docker.Makefile
include $(ROOT)/makefiles/terraform.Makefile
