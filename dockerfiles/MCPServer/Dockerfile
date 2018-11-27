FROM python:2.7-jessie

ARG ARCHIVEMATICA_SRC=.build_src/archivematica-fork/src
ARG DB_PATH=/var/archivematica/sharedDirectory/MCPServer.db

ENV DEBIAN_FRONTEND noninteractive
ENV DJANGO_SETTINGS_MODULE settings.common
ENV PYTHONPATH /src/MCPServer/lib/:/src/archivematicaCommon/lib/:/src/dashboard/src/
ENV PYTHONUNBUFFERED 1

ENV ARCHIVEMATICA_MCPSERVER_DB_URL sqlite:///$DB_PATH

# Environment variables from compose.yml
ENV DJANGO_SECRET_KEY 12345
ENV DJANGO_SETTINGS_MODULE settings.common
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_USER archivematica
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_PASSWORD demo
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_HOST mysql
ENV ARCHIVEMATICA_MCPSERVER_CLIENT_DATABASE MCP
ENV ARCHIVEMATICA_MCPSERVER_MCPSERVER_MCPARCHIVEMATICASERVER gearmand:4730
ENV ARCHIVEMATICA_MCPSERVER_SEARCH_ENABLED ${AM_SEARCH_ENABLED:-true}

RUN set -ex \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		gettext \
		libmysqlclient-dev \
		libldap2-dev \
		libsasl2-dev \
		locales \
		locales-all \
	&& rm -rf /var/lib/apt/lists/*

# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY $ARCHIVEMATICA_SRC/archivematicaCommon/requirements/ /src/archivematicaCommon/requirements/
COPY $ARCHIVEMATICA_SRC/dashboard/src/requirements/ /src/dashboard/src/requirements/
COPY $ARCHIVEMATICA_SRC/MCPServer/requirements/ /src/MCPServer/requirements/
RUN pip install -r /src/archivematicaCommon/requirements/production.txt -r /src/archivematicaCommon/requirements/dev.txt
RUN pip install -r /src/dashboard/src/requirements/production.txt -r /src/dashboard/src/requirements/dev.txt
RUN pip install -r /src/MCPServer/requirements/production.txt -r /src/MCPServer/requirements/dev.txt

COPY $ARCHIVEMATICA_SRC/archivematicaCommon/ /src/archivematicaCommon/
COPY $ARCHIVEMATICA_SRC/dashboard/ /src/dashboard/
COPY $ARCHIVEMATICA_SRC/MCPServer/ /src/MCPServer/


COPY $ARCHIVEMATICA_SRC/dashboard/src/manage.py /src/MCPServer/manage.py
#WORKDIR /src/MCPServer/
#RUN /src/MCPServer/manage.py migrate
#RUN chmod +w $DB_PATH
#WORKDIR /

RUN set -ex \
	&& groupadd --gid 333 --system archivematica \
	&& useradd --uid 333 --gid 333 --system archivematica

RUN set -ex \
	&& mkdir -p /var/archivematica/sharedDirectory \
	&& chown -R archivematica:archivematica /var/archivematica

COPY MCPServer/entrypoint.sh /src/entrypoint.sh
RUN chmod +x /src/MCPServer/entrypoint.sh

USER archivematica

#ENTRYPOINT /src/MCPServer/lib/archivematicaMCP.py
#ENTRYPOINT sleep infinity
ENTRYPOINT ["/src/MCPServer/entrypoint.sh"]

# volume arguments:
# ARCHIVEMATICA_SRC=.build_src/archivematica-fork/src
# -v $ARCHIVEMATICA_SRC/archivematicaCommon/:/src/archivematicaCommon/ -v $ARCHIVEMATICA_SRC/dashboard/:/src/dashboard/ -v $ARCHIVEMATICA_SRC/MCPServer/:/src/MCPServer -v /Users/rossrochford/.am/am-pipeline-data/:/var/archivematica/sharedDirectory

# original volume lines from yml file:
#- "../src/archivematica/src/archivematicaCommon/:/src/archivematicaCommon/"
#- "../src/archivematica/src/dashboard/:/src/dashboard/"
#- "../src/archivematica/src/MCPServer/:/src/MCPServer/"
#- "archivematica_pipeline_data:/var/archivematica/sharedDirectory:rw"