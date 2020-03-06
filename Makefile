ACCOUNT_ID = 299497370133
ROOT = $(shell git rev-parse --show-toplevel)

export INFRA_BUCKET = wellcomecollection-workflow-infra

include $(ROOT)/makefiles/docker.Makefile

include dockerfiles/Makefile

lambda-publish: s3_start_transfer-publish
lambda-test: s3_start_transfer-test
