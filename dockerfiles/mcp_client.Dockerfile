FROM wellcome/archivematica_base

COPY install_mcp_client.sh /
RUN /install_mcp_client.sh

# The installation instructions tell you to run
#
#     $ service start archivematica-mcp-client
#
# That gives us an "unrecognised service" error, so I'm running the service by
# hand from the contents of the service definition:
#
#     /lib/systemd/system/archivematica-mcp-client.service
#
RUN cat /lib/systemd/system/archivematica-mcp-client.service

ENV PATH=/usr/share/archivematica/virtualenvs/archivematica-mcp-client/bin:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
ENV PYTHONPATH=/usr/lib/archivematica/MCPClient:/usr/lib/archivematica/archivematicaCommon/:/usr/share/archivematica/dashboard/

ENV DJANGO_SETTINGS_MODULE=settings.common

ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_HOST=localhost
ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_DATABASE=
ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_USER=
ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_PASSWORD=

ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_ELASTICSEARCHSERVER=localhost:9200
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_MCPARCHIVEMATICASERVER=localhost:4730
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_SERVER=/var/run/clamav/clamd.ctl

ENV REQUEST_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

CMD ["/usr/share/archivematica/virtualenvs/archivematica-mcp-client/bin/python", "/usr/lib/archivematica/MCPClient/archivematicaClient.py"]
