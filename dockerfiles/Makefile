ROOT = $(shell git rev-parse --show-toplevel)
DOCKERFILES = $(ROOT)/dockerfiles

include $(ROOT)/functions.Makefile

archivematica_base-build:
	$(call build_image,archivematica_base,dockerfiles/archivematica_base/Dockerfile)

dashboard-build: archivematica_base-build
	$(call build_image,archivematica_dashboard,dockerfiles/dashboard/Dockerfile)

mcp_client-build: archivematica_base-build
	$(call build_image,archivematica_mcp_client,dockerfiles/mcp_client/Dockerfile)

mcp_server-build: archivematica_base-build
	$(call build_image,archivematica_mcp_server,dockerfiles/mcp_server/Dockerfile)

storage_service-build: archivematica_base-build
	$(call build_image,archivematica_storage_service,dockerfiles/storage_service/Dockerfile)


dashboard-publish: dashboard-build
	$(call publish_service,archivematica_dashboard)

storage_service-publish: mcp_server-build
	$(call publish_service,archivematica_storage_service)
