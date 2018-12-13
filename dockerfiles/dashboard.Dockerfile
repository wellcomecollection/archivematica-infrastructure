FROM wellcome/archivematica_base

COPY install_dashboard.sh /
RUN /install_dashboard.sh

# The installation instructions tell you to run
#
#     $ service start archivematica-dashboard
#
# That gives us an "unrecognised service" error, so I'm running the service by
# hand from the contents of the service definition:
#
#     /lib/systemd/system/archivematica-dashboard.service
#
WORKDIR /usr/share/archivematica/dashboard/

ENV PYTHONPATH=/usr/lib/archivematica/archivematicaCommon:/usr/share/archivematica/dashboard

ENV AM_GUNICORN_BIND=127.0.0.1:8002
ENV ARCHIVEMATICA_DASHBOARD_DASHBOARD_ELASTICSEARCH_SERVER=127.0.0.1:9200
ENV DJANGO_SETTINGS_MODULE=settings.production
ENV ARCHIVEMATICA_DASHBOARD_DASHBOARD_DJANGO_ALLOWED_HOSTS=*
ENV ARCHIVEMATICA_DASHBOARD_DASHBOARD_DJANGO_SECRET_KEY="1jirTAmXxpgZyg1dJNQPFRmaqHYy1YEf"
ENV ARCHIVEMATICA_DASHBOARD_CLIENT_HOST=localhost
ENV ARCHIVEMATICA_DASHBOARD_CLIENT_DATABASE=
ENV ARCHIVEMATICA_DASHBOARD_CLIENT_USER=
ENV ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD=

ENV REQUEST_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# Install the storage service package.
# The DEBIAN_FRONTEND variable tells 'apt-get' that we're can't give input;
# otherwise it tries to ask the user for a MySQL root password.
RUN DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-storage-service

# Install the mcp server packages.  We set DEBIAN_FRONTEND so we don't get asked
# for a MySQL root password.
RUN DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-mcp-server

RUN chown -R archivematica:archivematica /var/log/archivematica

CMD ["/usr/share/archivematica/virtualenvs/archivematica-dashboard/bin/gunicorn", "--config", "/etc/archivematica/dashboard.gunicorn-config.py", "wsgi:application"]
