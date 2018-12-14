ROOT = $(shell git rev-parse --show-toplevel)
DOCKERFILES = $(ROOT)/dockerfiles

include $(ROOT)/functions.Makefile

archivematica_base-build:
	$(call build_image,archivematica_base,dockerfiles/archivematica_base/Dockerfile)
