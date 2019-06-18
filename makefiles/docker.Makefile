IMAGE_BUILDER_IMAGE = wellcome/image_builder:25
PUBLISH_SERVICE_IMAGE = wellcome/publish_service:60


# Build and tag a Docker image.
#
# Args:
#   $1 - Name of the image.
#   $2 - Path to the Dockerfile, relative to the root of the repo.
#
define build_image
	$(ROOT)/docker_run.py --dind -- $(IMAGE_BUILDER_IMAGE) --name=$(1) --path=$(2)
endef


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

s3_starttransfer-publish:
	$(call publish_lambda,s3_starttransfer)


# Publish a Docker image to ECR, and put its associated release ID in S3.
#
# Args:
#   $1 - Name of the Docker image.
#
define publish_service
	$(ROOT)/docker_run.py \
	    --aws --dind -- \
	    $(PUBLISH_SERVICE_IMAGE) \
			--project_id=archivematica \
			--service_id=$(1) \
			--account_id=$(ACCOUNT_ID) \
			--region_id=eu-west-1 \
			--namespace=uk.ac.wellcome
endef
