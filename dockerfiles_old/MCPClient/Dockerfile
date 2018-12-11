FROM ubuntu:14.04

ARG ARCHIVEMATICA_SRC=.build_src/archivematica-fork/src
ARG DB_PATH=/var/archivematica/sharedDirectory/MCPClient.db

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE settings.common
ENV PYTHONPATH /src/MCPClient/lib/:/src/archivematicaCommon/lib/:/src/dashboard/src/
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_ARCHIVEMATICACLIENTMODULES /src/MCPClient/lib/archivematicaClientModules
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLIENTASSETSDIRECTORY /src/MCPClient/lib/assets/
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLIENTSCRIPTSDIRECTORY /src/MCPClient/lib/clientScripts/
ENV ARCHIVEMATICA_MCPCLIENT_DB_URL sqlite:///$DB_PATH

# Environment variables from compose.yml
ENV DJANGO_SECRET_KEY 12345
ENV DJANGO_SETTINGS_MODULE settings.common
ENV NAILGUN_SERVER fits
ENV NAILGUN_PORT 2113
ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_USER archivematica
ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_PASSWORD demo
ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_HOST mysql
ENV ARCHIVEMATICA_MCPCLIENT_CLIENT_DATABASE MCP
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_ELASTICSEARCHSERVER elasticsearch:9200
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_MCPARCHIVEMATICASERVER gearmand:4730
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_SEARCH_ENABLED ${AM_SEARCH_ENABLED:-true}
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CAPTURE_CLIENT_SCRIPT_OUTPUT ${AM_CAPTURE_CLIENT_SCRIPT_OUTPUT:-true}
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_SERVER clamavd:3310
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_FILE_SIZE ${CLAMAV_MAX_FILE_SIZE}
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_SCAN_SIZE ${CLAMAV_MAX_SCAN_SIZE}
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_MAX_STREAM_LENGTH ${CLAMAV_MAX_STREAM_LENGTH}
ENV ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_BACKEND clamdscanner


RUN set -ex \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		apt-transport-https \
		curl \
		git \
		python-software-properties \
		software-properties-common \
		libldap2-dev \
		libsasl2-dev \
	&& rm -rf /var/lib/apt/lists/*

# OS dependencies
RUN set -ex \
	&& curl -s https://packages.archivematica.org/GPG-KEY-archivematica | apt-key add - \
	&& add-apt-repository "deb [arch=amd64] http://packages.archivematica.org/1.7.x/ubuntu-externals trusty main" \
	&& add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ trusty multiverse" \
	&& add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ trusty-security universe" \
	&& add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ trusty-updates multiverse" \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		atool \
		bagit \
		bulk-extractor \
		clamav \
		ffmpeg \
		ghostscript \
		libavcodec-extra-56 \
		fits \
		imagemagick \
		inkscape \
		jhove \
		libimage-exiftool-perl \
		libevent-dev \
		libjansson4 \
		libxml2-utils \
		md5deep \
		mediainfo \
		nailgun-client \
		openjdk-7-jre-headless \
		p7zip-full \
		pbzip2 \
		readpst \
		rsync \
		siegfried \
		sleuthkit \
		tesseract-ocr \
		tree \
		ufraw \
		unrar-free \
		uuid \
	&& rm -rf /var/lib/apt/lists/*

# Download ClamAV virus signatures
RUN freshclam --quiet

# Build dependencies
RUN set -ex \
	&& curl -s https://bootstrap.pypa.io/get-pip.py | python \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		python-dev \
		libmysqlclient-dev \
		libffi-dev \
		libyaml-dev \
		libssl-dev \
		libxml2-dev \
		libxslt-dev \
	&& rm -rf /var/lib/apt/lists/*

# OS dependencies from .deb files
RUN set -ex \
  && curl -s https://mediaarea.net/download/binary/libzen0/0.4.37/libzen0_0.4.37-1_amd64.xUbuntu_14.04.deb --output libzen0_0.4.37-1_amd64.xUbuntu_14.04.deb \
  && curl -s https://mediaarea.net/download/binary/libmediainfo0/18.03/libmediainfo0_18.03-1_amd64.xUbuntu_14.04.deb --output libmediainfo0_18.03-1_amd64.xUbuntu_14.04.deb \
  && curl -s https://mediaarea.net/download/binary/mediaconch/18.03/mediaconch_18.03-1_amd64.xUbuntu_14.04.deb --output mediaconch_18.03-1_amd64.xUbuntu_14.04.deb \
  && dpkg -i libzen0_0.4.37-1_amd64.xUbuntu_14.04.deb \
  && dpkg -i libmediainfo0_18.03-1_amd64.xUbuntu_14.04.deb \
  && dpkg -i mediaconch_18.03-1_amd64.xUbuntu_14.04.deb \
  && rm libzen0_0.4.37-1_amd64.xUbuntu_14.04.deb \
  && rm libmediainfo0_18.03-1_amd64.xUbuntu_14.04.deb \
  && rm mediaconch_18.03-1_amd64.xUbuntu_14.04.deb

COPY $ARCHIVEMATICA_SRC/archivematicaCommon/requirements/ /src/archivematicaCommon/requirements/
COPY $ARCHIVEMATICA_SRC/dashboard/src/requirements/ /src/dashboard/src/requirements/
COPY $ARCHIVEMATICA_SRC/MCPClient/requirements/ /src/MCPClient/requirements/

RUN pip install -r /src/archivematicaCommon/requirements/production.txt -r /src/archivematicaCommon/requirements/dev.txt
RUN pip install -r /src/dashboard/src/requirements/production.txt -r /src/dashboard/src/requirements/dev.txt
RUN pip install -r /src/MCPClient/requirements/production.txt -r /src/MCPClient/requirements/dev.txt

COPY $ARCHIVEMATICA_SRC/archivematicaCommon/ /src/archivematicaCommon/
COPY $ARCHIVEMATICA_SRC/dashboard/ /src/dashboard/
COPY $ARCHIVEMATICA_SRC/MCPClient/ /src/MCPClient/

# Some scripts in archivematica-fpr-admin executed by MCPClient rely on certain
# files being available in this image (e.g. see https://git.io/vA1wF).
COPY $ARCHIVEMATICA_SRC/archivematicaCommon/lib/externals/fido/ /usr/lib/archivematica/archivematicaCommon/externals/fido/
COPY $ARCHIVEMATICA_SRC/archivematicaCommon/lib/externals/fiwalk_plugins/ /usr/lib/archivematica/archivematicaCommon/externals/fiwalk_plugins/

COPY $ARCHIVEMATICA_SRC/dashboard/src/manage.py /src/MCPClient/manage.py
COPY MCPClient/entrypoint.sh /src/MCPClient/entrypoint.sh
RUN chmod +x /src/MCPClient/entrypoint.sh

RUN set -ex \
	&& groupadd --gid 333 --system archivematica \
	&& useradd -m --uid 333 --gid 333 --system archivematica

USER archivematica

#ENTRYPOINT /src/MCPClient/lib/archivematicaClient.py
#ENTRYPOINT sleep infinity
ENTRYPOINT ["/src/MCPClient/entrypoint.sh"]

# volume arguments:
# ARCHIVEMATICA_SRC=.build_src/archivematica-fork/src
# -v $ARCHIVEMATICA_SRC/archivematicaCommon/:/src/archivematicaCommon/ -v $ARCHIVEMATICA_SRC/dashboard/:/src/dashboard/ -v $ARCHIVEMATICA_SRC/MCPClient/:/src/MCPClient -v /Users/rossrochford/.am/am-pipeline-data/:/var/archivematica/sharedDirectory

# original volume lines from yml file:
#- "../src/archivematica/src/archivematicaCommon/:/src/archivematicaCommon/"
#- "../src/archivematica/src/dashboard/:/src/dashboard/"
#- "../src/archivematica/src/MCPClient/:/src/MCPClient/"
#- "archivematica_pipeline_data:/var/archivematica/sharedDirectory:rw"