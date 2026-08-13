#!/usr/bin/env bash
# Runs the test suite for one of the Lambdas, e.g. run_lambda_tests.sh transfer_monitor

set -o errexit
set -o nounset
set -o pipefail

LAMBDA="$1"

ROOT=$(git rev-parse --show-toplevel)
PYTHON_VERSION=$(< "$ROOT/.python-version")
UV_IMAGE="ghcr.io/astral-sh/uv:python${PYTHON_VERSION}-trixie"

docker run --rm \
  --volume "$ROOT/lambdas/$LAMBDA:/workspace:ro" \
  --workdir /workspace \
  --env LAMBDA="$LAMBDA" \
  --env COVERAGE_FILE="/tmp/$LAMBDA.coverage" \
  --env PYTHON_VERSION="$PYTHON_VERSION" \
  --env PYTHONDONTWRITEBYTECODE=1 \
  --env UV_PYTHON_DOWNLOADS=never \
  --entrypoint /bin/bash \
  "$UV_IMAGE" \
  -e -c '
    uv venv --python "$PYTHON_VERSION" "/tmp/${LAMBDA}_venv"
    uv pip sync \
      --python "/tmp/${LAMBDA}_venv/bin/python" \
      test_requirements.txt
    "/tmp/${LAMBDA}_venv/bin/python" \
      -m coverage run -m pytest -p no:cacheprovider
    "/tmp/${LAMBDA}_venv/bin/python" -m coverage report
  '
