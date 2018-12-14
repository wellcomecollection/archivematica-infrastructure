IMAGE_BUILDER_IMAGE = wellcome/image_builder:latest


# Build and tag a Docker image.
#
# Args:
#   $1 - Name of the image.
#   $2 - Path to the Dockerfile, relative to the root of the repo.
#
define build_image
	$(ROOT)/docker_run.py --dind -- $(IMAGE_BUILDER_IMAGE) --name=$(1) --path=$(2)
endef
