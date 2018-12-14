ROOT = $(shell git rev-parse --show-toplevel)

export TFVARS_BUCKET = wellcomecollection-workflow-infra
export TFVARS_KEY    = terraform/archivematica.tfvars
export TFPLAN_BUCKET = wellcomecollection-workflow-infra

include $(ROOT)/makefiles/docker.Makefile
include $(ROOT)/makefiles/terraform.Makefile
