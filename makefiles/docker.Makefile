IMAGE_BUILDER_IMAGE = wellcome/image_builder:25
PUBLISH_SERVICE_IMAGE = wellcome/publish_service:60


# Publish a ZIP file containing a Lambda definition to S3.
#
# Args:
#   $1 - Path to the Lambda src directory, relative to the root of the repo.
#
define publish_lambda
    $(ROOT)/docker_run.py --aws --root --dind -- \
        wellcome/publish_lambda:14 \
        "$(1)" --key="lambdas/$(1).zip" --bucket="$(INFRA_BUCKET)"
endef
