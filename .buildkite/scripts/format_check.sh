#!/usr/bin/env bash
# Fails the build on unformatted Terraform or Python; run `terraform fmt -recursive` and `ruff format` to fix.
# Files copied from Artefactual (the overlay directories) are excluded.
set -o errexit
set -o nounset

ROOT=$(git rev-parse --show-toplevel)

docker run --tty --rm \
  --volume "$ROOT":/repo \
  --workdir /repo \
  "public.ecr.aws/hashicorp/terraform:light" fmt -check -recursive -diff

docker run --tty --rm \
  --volume "$ROOT":/repo \
  --workdir /repo \
  "ghcr.io/astral-sh/ruff:0.16.1" \
  format --check --diff --extend-exclude ".lambda_zips,.terraform,target,*.ipynb,*.md,overlay" .
