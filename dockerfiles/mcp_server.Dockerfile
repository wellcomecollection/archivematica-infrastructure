FROM wellcome/archivematica_base

COPY install_mcp_server.sh /
RUN /install_mcp_server.sh

# The installation instructions tell you to run
#
#     $ service start archivematica-mcp-server
#
# That gives us an "unrecognised service" error, so I'm running the service by
# hand from the contents of the service definition:
#
#     /lib/systemd/system/archivematica-mcp-server.service
#
ENV PYTHONPATH=/usr/lib/archivematica/archivematicaCommon/:/usr/share/archivematica/dashboard/

ENV DJANGO_SETTINGS_MODULE=settings.common
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_HOST=localhost
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_DATABASE=MCP
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_USER=archivematica
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_PASSWORD=1O5N5UCiFoQP

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y archivematica-storage-service

RUN apt-get install -y curl

RUN set -ex \
	&& mkdir -p /var/archivematica/sharedDirectory \
	&& chown -R archivematica:archivematica /var/archivematica \
  && chown -R archivematica:archivematica /var/log/archivematica

USER archivematica

COPY run_mcp_server.sh /
CMD ["/run_mcp_server.sh"]
