FROM wellcome/archivematica_base

COPY install_storage_service.sh /
RUN /install_storage_service.sh

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
ENV SS_GUNICORN_BIND=127.0.0.1:8001

ENV REQUEST_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

CMD ["/usr/share/archivematica/virtualenvs/archivematica-storage-service/bin/gunicorn", "--config", "/etc/archivematica/storage-service.gunicorn-config.py", "storage_service.wsgi:application"]