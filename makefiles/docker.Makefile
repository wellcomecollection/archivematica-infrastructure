IMAGE_BUILDER_IMAGE = wellcome/image_builder:25
PUBLISH_SERVICE_IMAGE = wellcome/publish_service


# Build and tag a Docker image.
#
# Args:
#   $1 - Name of the image.
#   $2 - Path to the Dockerfile, relative to the root of the repo.
#
define build_image
	$(ROOT)/docker_run.py --dind -- $(IMAGE_BUILDER_IMAGE) --name=$(1) --path=$(2)
endef


# Publish a Docker image to ECR, and put its associated release ID in S3.
#
# Args:
#   $1 - Name of the Docker image.
#
define publish_service
	$(ROOT)/docker_run.py \
	    --aws --dind -- \
	    $(PUBLISH_SERVICE_IMAGE) \
			--image_name="$(1)" \
			--project_name="archivematica"
endef
