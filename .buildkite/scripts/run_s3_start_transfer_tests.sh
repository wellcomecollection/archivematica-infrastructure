#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(git rev-parse --show-toplevel)
PYTHON_VERSION=$(< "$ROOT/.python-version")
UV_IMAGE="ghcr.io/astral-sh/uv:python${PYTHON_VERSION}-trixie"

docker run --rm \
  --volume "$ROOT/lambdas/s3_start_transfer:/workspace:ro" \
  --workdir /workspace \
  --env COVERAGE_FILE=/tmp/s3_start_transfer.coverage \
  --env PYTHON_VERSION="$PYTHON_VERSION" \
  --env PYTHONDONTWRITEBYTECODE=1 \
  --env UV_PYTHON_DOWNLOADS=never \
  --entrypoint /bin/bash \
  "$UV_IMAGE" \
  -e -c '
    uv venv --python "$PYTHON_VERSION" /tmp/s3_start_transfer_venv
    uv pip sync \
      --python /tmp/s3_start_transfer_venv/bin/python \
      test_requirements.txt
    /tmp/s3_start_transfer_venv/bin/python \
      -m coverage run -m pytest -p no:cacheprovider
    /tmp/s3_start_transfer_venv/bin/python -m coverage report
  '
