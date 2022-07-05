ROOT = $(shell git rev-parse --show-toplevel)
DOCKERFILES = $(ROOT)/dockerfiles

include $(ROOT)/makefiles/docker.Makefile

dashboard_nginx-build:
	$(ROOT)/docker_run.py --dind -- $(IMAGE_BUILDER_IMAGE) \
		--name=archivematica_dashboard_nginx \
		--path=dockerfiles/dashboard_nginx/Dockerfile

storage_service_nginx-build:
	$(ROOT)/docker_run.py --dind -- $(IMAGE_BUILDER_IMAGE) \
		--name=archivematica_storage_service_nginx \
		--path=dockerfiles/storage_service_nginx/Dockerfile

clamavd-build:
	$(ROOT)/docker_run.py --dind -- $(IMAGE_BUILDER_IMAGE) \
		--name=clamavd \
		--path=dockerfiles/clamavd/Dockerfile


dashboard_nginx-publish: dashboard_nginx-build
	$(call publish_service,archivematica_dashboard_nginx)

storage_service_nginx-publish: storage_service_nginx-build
	$(call publish_service,archivematica_storage_service_nginx)

clamavd-publish: clamavd-build
	$(call publish_service,clamavd)
