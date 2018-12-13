#!/usr/bin/env bash

set -o errexit
set -o nounset

pushd dockerfiles
  docker build -t "$1" -f "$1.Dockerfile" .
popd
