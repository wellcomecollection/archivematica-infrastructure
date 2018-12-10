ROOT = $(shell git rev-parse --show-toplevel)

export TFVARS_BUCKET = wellcomecollection-workflow-infra
export TFVARS_KEY    = terraform/workflow.tfvars
export TFPLAN_BUCKET = wellcomecollection-workflow-infra

include $(ROOT)/makefiles/terraform.Makefile
