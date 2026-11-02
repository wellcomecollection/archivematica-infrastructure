#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

ROOT=$(git rev-parse --show-toplevel)

docker run --tty --rm \
	--volume "$ROOT:/repo" \
	--workdir /repo \
	"public.ecr.aws/hashicorp/terraform:light" fmt -recursive

docker run --tty --rm \
  --volume "$ROOT":/repo \
  --workdir /repo \
  "ghcr.io/astral-sh/ruff:0.16.1" \
  format --extend-exclude ".lambda_zips,.terraform,target,*.ipynb,*.md,overlay" .

# We don't want to autoformat files which are copied out of an Artefactual
# repo; it would muddy the diffs.
git checkout archivematica-apps/archivematica/overlay
git checkout archivematica-apps/archivematica-storage-service/overlay
