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
	$(ROOT)/docker_run.py \
	    --aws --dind -- \
	    $(PUBLISH_SERVICE_IMAGE) \
			--project_id=archivematica \
			--service_id=archivematica_dashboard_nginx \
			--account_id=$(ACCOUNT_ID) \
			--region_id=eu-west-1 \
			--namespace=uk.ac.wellcome

storage_service_nginx-publish: storage_service_nginx-build
	$(ROOT)/docker_run.py \
	    --aws --dind -- \
	    $(PUBLISH_SERVICE_IMAGE) \
			--project_id=archivematica \
			--service_id=archivematica_storage_service_nginx \
			--account_id=$(ACCOUNT_ID) \
			--region_id=eu-west-1 \
			--namespace=uk.ac.wellcome

clamavd-publish: clamavd-build
	$(ROOT)/docker_run.py \
	    --aws --dind -- \
	    $(PUBLISH_SERVICE_IMAGE) \
			--project_id=archivematica \
			--service_id=clamavd \
			--account_id=$(ACCOUNT_ID) \
			--region_id=eu-west-1 \
			--namespace=uk.ac.wellcome
