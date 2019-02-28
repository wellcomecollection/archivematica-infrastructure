ROOT = $(shell git rev-parse --show-toplevel)
DOCKERFILES = $(ROOT)/dockerfiles

include $(ROOT)/functions.Makefile

archivematica_base-build:
	$(call build_image,archivematica_base,dockerfiles/archivematica_base/Dockerfile)

dashboard_nginx-build: dashboard-build
	$(call build_image,archivematica_dashboard_nginx,dockerfiles/dashboard_nginx/Dockerfile)

storage_service-build: archivematica_base-build
	$(call build_image,archivematica_storage_service,dockerfiles/storage_service/Dockerfile)

storage_service_nginx-build: storage_service-build
	$(call build_image,archivematica_storage_service_nginx,dockerfiles/storage_service_nginx/Dockerfile)


dashboard_nginx-publish: dashboard_nginx-build
	$(call publish_service,archivematica_dashboard_nginx)

storage_service-publish: storage_service-build
	$(call publish_service,archivematica_storage_service)

storage_service_nginx-publish: storage_service_nginx-build
	$(call publish_service,archivematica_storage_service_nginx)
