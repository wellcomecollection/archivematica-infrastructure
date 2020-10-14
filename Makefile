ACCOUNT_ID = 299497370133
ROOT = $(shell git rev-parse --show-toplevel)

export INFRA_BUCKET = wellcomecollection-workflow-infra

include $(ROOT)/makefiles/docker.Makefile

include dockerfiles/Makefile

s3_start_transfer-publish:
	$(call publish_lambda,s3_start_transfer)

s3_start_transfer-test:
	$(call test_python,s3_start_transfer)

start_test_transfer-publish:
	$(call publish_lambda,start_test_transfer)

lambda-publish: s3_start_transfer-publish start_test_transfer-publish
lambda-test: s3_start_transfer-test
