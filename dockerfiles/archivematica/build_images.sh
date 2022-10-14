#!/usr/bin/env bash

set -o errexit
set -o nounset

ROOT=$(git rev-parse --show-toplevel)

ARCHIVEMATICA_TAG=v1.13.2

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
    docker tag "archivematica-$service" "archivematica-$service:$ARCHIVEMATICA_TAG"
  done
popd