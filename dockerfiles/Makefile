ROOT = $(shell git rev-parse --show-toplevel)
DOCKERFILES = $(ROOT)/dockerfiles

include $(ROOT)/functions.Makefile

archivematica_base-build:
	$(call build_image,archivematica_base,dockerfiles/archivematica_base/Dockerfile)

dashboard-build: archivematica_base-build
	$(call build_image,archivematica_dashboard,dockerfiles/dashboard/Dockerfile)

dashboard_nginx-build: dashboard-build
	$(call build_image,archivematica_dashboard_nginx,dockerfiles/dashboard_nginx/Dockerfile)

mcp_client-build: archivematica_base-build
	$(call build_image,archivematica_mcp_client,dockerfiles/mcp_client/Dockerfile)

mcp_server-build: archivematica_base-build
	$(call build_image,archivematica_mcp_server,dockerfiles/mcp_server/Dockerfile)

storage_service-build: archivematica_base-build
	$(call build_image,archivematica_storage_service,dockerfiles/storage_service/Dockerfile)

storage_service_nginx-build: storage_service-build
	$(call build_image,archivematica_storage_service_nginx,dockerfiles/storage_service_nginx/Dockerfile)

build: dashboard_nginx-build storage_service_nginx-build mcp_client-build mcp_server-build

dashboard-publish: dashboard-build
	$(call publish_service,archivematica_dashboard)

dashboard_nginx-publish: dashboard_nginx-build
	$(call publish_service,archivematica_dashboard_nginx)

mcp_client-publish: mcp_client-build
	$(call publish_service,archivematica_mcp_client)

mcp_server-publish: mcp_server-build
	$(call publish_service,archivematica_mcp_server)

storage_service-publish: storage_service-build
	$(call publish_service,archivematica_storage_service)

storage_service_nginx-publish: storage_service_nginx-build
	$(call publish_service,archivematica_storage_service_nginx)
