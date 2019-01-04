include functions.Makefile
include formatting.Makefile

export AWS_PROFILE = wellcomedigitalworkflow

tf-plan:
	$(call terraform_plan,terraform,false)

tf-apply:
	$(call terraform_apply,terraform)

tf-import:
	$(call terraform_import,terraform,terraform)

include dockerfiles/Makefile
