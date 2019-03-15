ROOT = $(shell git rev-parse --show-toplevel)
DOCKERFILES = $(ROOT)/dockerfiles

include $(ROOT)/functions.Makefile

dashboard_nginx-build:
	$(call build_image,archivematica_dashboard_nginx,dockerfiles/dashboard_nginx/Dockerfile)

storage_service_nginx-build:
	$(call build_image,archivematica_storage_service_nginx,dockerfiles/storage_service_nginx/Dockerfile)


dashboard_nginx-publish: dashboard_nginx-build
	$(call publish_service,archivematica_dashboard_nginx)

storage_service_nginx-publish: storage_service_nginx-build
	$(call publish_service,archivematica_storage_service_nginx)


fits_ngserver-build:
	$(call build_image,fits_ngserver,dockerfiles/fits_ngserver/Dockerfile)

fits_ngserver-publish: fits_ngserver-build
	$(call publish_service,fits_ngserver)
