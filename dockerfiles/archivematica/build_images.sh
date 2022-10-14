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

  echo "*** Applying vendored files to repository"
  python3 "$ROOT/dockerfiles/archivematica/copy_vendored_files.py"
  git status
popd