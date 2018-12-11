FROM ubuntu:18.04

LABEL maintainer "Wellcome Digital Workflow <wellcomedigitalworkflow@wellcome.ac.uk>"

COPY install_archivematica_base.sh /
RUN /install_archivematica_base.sh
