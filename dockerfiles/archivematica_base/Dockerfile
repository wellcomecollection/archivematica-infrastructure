# The base image for all our Archivematica services.
#
# This image includes some base components, plus some helper scripts for installing
# components in other images.

FROM ubuntu:18.04

LABEL maintainer "Wellcome Digital Workflow <wellcomedigitalworkflow@wellcome.ac.uk>"

COPY install_archivematica_base.sh /
RUN /install_archivematica_base.sh

COPY install_apt_packages.sh /
