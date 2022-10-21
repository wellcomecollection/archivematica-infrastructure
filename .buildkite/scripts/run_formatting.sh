#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

ECR_REGISTRY="760097843905.dkr.ecr.eu-west-1.amazonaws.com"

ROOT=$(git rev-parse --show-toplevel)

docker run --tty --rm \
	--volume "$ROOT:/repo" \
	--workdir /repo \
	"public.ecr.aws/hashicorp/terraform:light" fmt -recursive

docker run --tty --rm \
	--volume "$ROOT:/repo" \
	"$ECR_REGISTRY/wellcome/format_python:112"

# We don't want to autoformat files which are copied out of an Artefactual
# repo; it would muddy the diffs.
git checkout dockerfiles/archivematica/overlay
git checkout dockerfiles/archivematica-storage-service/overlay
