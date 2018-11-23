FROM python:2.7-jessie

ENV DEBIAN_FRONTEND noninteractive
ENV DJANGO_SETTINGS_MODULE storage_service.settings.production
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH /src/storage_service  # todo: will need to be changed I think
#ENV SS_GUNICORN_BIND 0.0.0.0:8000
#ENV SS_GUNICORN_CHDIR /src/storage_service
#ENV SS_GUNICORN_ACCESSLOG -
#ENV SS_GUNICORN_ERRORLOG -
ENV FORWARDED_ALLOW_IPS *

# OS dependencies
RUN set -ex \
	&& apt-get update -qq \
	&& apt-get install -qq -y --no-install-recommends \
		gettext \
		gnupg \
		p7zip-full \
		rsync \
		unar \
		locales \
		locales-all \
	&& rm -rf /var/lib/apt/lists/*

# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV SS_DB_URL sqlite:storage_service.db
ENV DJANGO_SECRET_KEY 12345
ENV DJANGO_ALLOWED_HOSTS *

ADD .build_src/archivematica-storage-service/requirements/ /src/requirements/
RUN pip install -q -r /src/requirements/production.txt -r /src/requirements/test.txt
ADD .build_src/archivematica-storage-service/ /src/
ADD .build_src/archivematica-storage-service/install/storage-service.gunicorn-config.py /etc/archivematica/storage-service.gunicorn-config.py

COPY .build_src/archivematica-sampledata/ /src/archivematica-sampledata/


RUN set -ex \
	&& groupadd --gid 333 --system archivematica \
	&& useradd --uid 333 --gid 333 --system archivematica

RUN set -ex \
	&& internalDirs=' \
		/db \
		/src/storage_service/assets \
		/src/storage_service/locations/fixtures \
		/var/archivematica/storage_service \
	' \
	&& mkdir -p $internalDirs \
	&& chown -R archivematica:archivematica $internalDirs

COPY storage_service/cmd.sh /src/cmd.sh
RUN chmod +x /src/cmd.sh

# USER archivematica

#RUN env \
#	DJANGO_SETTINGS_MODULE=storage_service.settings.local \
#	SS_DB_URL=mysql://ne:ver@min/d \
#		/src/storage_service/manage.py collectstatic --noinput --clear

EXPOSE 8003
WORKDIR /src/storage_service

# ENTRYPOINT /usr/local/bin/gunicorn --config=/etc/archivematica/storage-service.gunicorn-config.py storage_service.wsgi:application

CMD ["/src/cmd.sh"]
