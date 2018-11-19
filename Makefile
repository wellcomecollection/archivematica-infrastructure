include functions.Makefile
include formatting.Makefile

tf-plan:
	$(call terraform_plan,$(ROOT)/terraform,false)

tf-apply:
	$(call terraform_apply,$(ROOT)/terraform)
