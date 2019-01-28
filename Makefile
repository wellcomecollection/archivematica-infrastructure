include functions.Makefile
include formatting.Makefile

export AWS_PROFILE = workflow-dev

tf-plan:
	$(call terraform_plan,terraform,false)

tf-apply:
	$(call terraform_apply,terraform)

tf-import:
	$(call terraform_import,terraform,terraform)


restart-am-services:  ## Restart Archivematica services: MCPServer, MCPClient, Dashboard and Storage Service.
	docker-compose restart archivematica-mcp-server
	docker-compose restart archivematica-mcp-client
	docker-compose restart archivematica-dashboard
	docker-compose restart archivematica-storage-service


bootstrap-dashboard-db:  ## Bootstrap Dashboard (new database).
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "\
		DROP DATABASE IF EXISTS MCP; \
		CREATE DATABASE MCP; \
		GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /usr/share/archivematica/dashboard/manage.py \
			archivematica-dashboard \
				migrate --noinput

bootstrap-storage-service-db:  ## Boostrap Storage Service (new database).
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "\
		DROP DATABASE IF EXISTS SS; \
		CREATE DATABASE SS; \
		GRANT ALL ON SS.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /usr/share/archivematica/virtualenvs/archivematica-storage-service/bin/python \
			archivematica-storage-service \
			/usr/share/archivematica/virtualenvs/archivematica-storage-service/lib/python2.7/site-packages/storage_service/manage.py migrate --noinput


bootstrap: bootstrap-dashboard-db bootstrap-storage-service-db

docker-compose:
	docker-compose down
	docker-compose up -d
	sleep 30

dev: docker-compose bootstrap restart-am-services
	


include dockerfiles/Makefile
