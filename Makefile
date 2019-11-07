ACCOUNT_ID = 299497370133
ROOT = $(shell git rev-parse --show-toplevel)

include functions.Makefile
include formatting.Makefile

tf-plan:
	$(call terraform_plan,terraform/stack_staging,false)

tf-apply:
	$(call terraform_apply,terraform/stack_staging)

tf-import:
	$(call terraform_import,terraform/stack_staging,terraform)

include dockerfiles/Makefile

lambda-publish: s3_start_transfer-publish
lambda-test: s3_start_transfer-test
