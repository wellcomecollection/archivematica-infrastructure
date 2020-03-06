ROOT = $(shell git rev-parse --show-toplevel)

export INFRA_BUCKET = wellcomecollection-workflow-infra

include $(ROOT)/makefiles/docker.Makefile
