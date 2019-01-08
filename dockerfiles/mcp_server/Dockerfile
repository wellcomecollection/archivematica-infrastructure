FROM archivematica_base

ENV APT_INSTALL_DASHBOARD=yes
ENV APT_INSTALL_MCP_SERVER=yes
ENV APT_INSTALL_MCP_CLIENT=no
ENV APT_INSTALL_STORAGE_SERVICE=no

ENV APT_KEEP_VIRTUALENV=mcp-server

RUN /install_apt_packages.sh

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

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y archivematica-storage-service

# Install our custom settings, and tell Django that it should use this
# file in preference to the default.
#
COPY settings.py /usr/lib/archivematica/MCPServer/settings/wellcome.py
ENV DJANGO_SETTINGS_MODULE=settings.wellcome

CMD ["/usr/share/archivematica/virtualenvs/archivematica-mcp-server/bin/python", "/usr/lib/archivematica/MCPServer/archivematicaMCP.py"]
