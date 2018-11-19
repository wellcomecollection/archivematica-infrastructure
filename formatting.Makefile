ROOT = $(shell git rev-parse --show-toplevel)

format-terraform:
	$(ROOT)/docker_run.py --aws -- \
		--volume $(ROOT):/repo \
		--workdir /repo \
		hashicorp/terraform:light fmt

	git diff --exit-code

travis-format: format-terraform
