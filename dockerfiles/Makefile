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

nginx-build:
	$(call build_image,archivematica_nginx,dockerfiles/nginx/Dockerfile)


dashboard-publish: dashboard-build
	$(call publish_service,archivematica_dashboard)

mcp_client-publish: mcp_client-build
	$(call publish_service,archivematica_mcp_client)

mcp_server-publish: mcp_server-build
	$(call publish_service,archivematica_mcp_server)

storage_service-publish: storage_service-build
	$(call publish_service,archivematica_storage_service)

nginx-publish: nginx-build
	$(call publish_service,archivematica_nginx)


publish-all: dashboard-publish mcp_client-publish mcp_server-publish storage_service-publish nginx-publish
