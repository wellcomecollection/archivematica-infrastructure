ROOT = $(shell git rev-parse --show-toplevel)
DOCKERFILES = $(ROOT)/dockerfiles

PUBLISH_SERVICE_IMAGE = wellcome/publish_service:60

CURRENT_COMMIT=$(shell git rev-parse HEAD)

dashboard_nginx-build:
	docker build \
			--file dockerfiles/dashboard_nginx/Dockerfile \
			--tag archivematica_dashboard_nginx \
			dockerfiles/dashboard_nginx

storage_service_nginx-build:
	docker build \
			--file dockerfiles/storage_service_nginx/Dockerfile \
			--tag archivematica_storage_service_nginx \
			dockerfiles/storage_service_nginx

clamavd-build:
	docker build \
			--file dockerfiles/clamavd/Dockerfile \
			--tag clamavd \
			dockerfiles/clamavd

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
