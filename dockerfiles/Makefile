dashboard_nginx-build:
	./builds/build_docker_image.sh archivematica_dashboard_nginx

storage_service_nginx-build:
	./builds/build_docker_image.sh archivematica_storage_service_nginx

clamavd-build:
	./builds/build_docker_image.sh clamavd

dashboard_nginx-publish: dashboard_nginx-build
	./builds/publish_docker_image.sh archivematica_dashboard_nginx

storage_service_nginx-publish: storage_service_nginx-build
	./builds/publish_docker_image.sh archivematica_storage_service_nginx

clamavd-publish: clamavd-build
	./builds/publish_docker_image.sh clamavd
