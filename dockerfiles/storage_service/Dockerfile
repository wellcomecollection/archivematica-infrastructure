FROM archivematica_base

ENV APT_INSTALL_DASHBOARD=no
ENV APT_INSTALL_MCP_SERVER=no
ENV APT_INSTALL_MCP_CLIENT=no
ENV APT_INSTALL_STORAGE_SERVICE=yes

ENV APT_KEEP_VIRTUALENV=storage_service

RUN /install_apt_packages.sh

# We also need this package, or we get an error on startup:
#
#     ImproperlyConfigured: Error loading MySQLdb module: libmysqlclient.so.20:
#     cannot open shared object file: No such file or directory
#
RUN apt-get install --yes libmysqlclient20

# The installation instructions tell you to run
#
#     $ service start archivematica-storage-service
#
# That gives us an "unrecognised service" error, so I'm running the service by
# hand from the contents of the service definition:
#
#     /lib/systemd/system/archivematica-storage-service.service
#
WORKDIR /usr/lib/archivematica/storage-service

ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
ENV LC_LANG="en_US.UTF-8"

ENV SS_DB_NAME=/var/archivematica/storage-service/storage.db
ENV DJANGO_ALLOWED_HOSTS=*
ENV SS_DB_PASSWORD=
ENV SS_DB_USER=
ENV SS_DB_HOST=
ENV DJANGO_SETTINGS_MODULE=storage_service.settings.production
ENV DJANGO_SECRET_KEY="7290fac28a8b30d0017f2bfbcd299d24d2fb5358"
ENV SS_GUNICORN_BIND=0.0.0.0:8000

ENV REQUEST_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

COPY run_storage_service.sh /
CMD ["/run_storage_service.sh"]
