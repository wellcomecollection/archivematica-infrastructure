ACCOUNT_ID = 299497370133
ROOT = $(shell git rev-parse --show-toplevel)

export INFRA_BUCKET = wellcomecollection-workflow-infra

s3_start_transfer-publish:
	$(ROOT)/docker_run.py --aws --root --dind -- \
      wellcome/publish_lambda:14 \
      "$(1)" --key="lambdas/s3_start_transfer.zip" --bucket="$(INFRA_BUCKET)"

s3_start_transfer-test:
	$(ROOT)/docker_run.py --aws --root --dind -- \
		wellcome/build_test_python s3_start_transfer
	$(ROOT)/docker_run.py --aws --dind -- \
		--net=host \
		--volume $(ROOT)/shared_conftest.py:/conftest.py \
		--workdir $(ROOT)/s3_start_transfer --tty \
		wellcome/test_python_s3_start_transfer:latest

start_test_transfer-publish:
	$(ROOT)/docker_run.py --aws --root --dind -- \
      wellcome/publish_lambda:14 \
      "$(1)" --key="lambdas/start_test_transfer.zip" --bucket="$(INFRA_BUCKET)"

lambda-publish: s3_start_transfer-publish start_test_transfer-publish
lambda-test: s3_start_transfer-test
