#!/usr/bin/env bash

set -o errexit
set -o nounset

ARCHIVEMATICA_TAG=v1.13.2

ROOT=$(git rev-parse --show-toplevel)

eval $(env AWS_PROFILE=workflow-dev aws ecr get-login --no-include-email)

pushd $(mktemp -d)

  echo "*** Checking out the core Artefactual repository"
  git clone https://github.com/artefactual/archivematica.git
  cd archivematica

  echo "*** Checking out tag $ARCHIVEMATICA_TAG"
  git checkout "$ARCHIVEMATICA_TAG"

  echo "*** Applying overlay files to repository"
  python3 "$ROOT/dockerfiles/archivematica/copy_overlay_files.py"
  git status

  echo "*** Building the dashboard"
  cd hack

  for service in mcp-server mcp-client dashboard
  do
    docker-compose build "archivematica-$service"

    ECR_IMAGE_TAG="299497370133.dkr.ecr.eu-west-1.amazonaws.com/weco/archivematica-$service:$ARCHIVEMATICA_TAG"
    docker tag "hack_archivematica-$service" "$ECR_IMAGE_TAG"
    docker push "$ECR_IMAGE_TAG"
  done
popd