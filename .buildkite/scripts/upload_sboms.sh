#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [[ "${BUILDKITE_BRANCH:-}" != "main" || "${BUILDKITE_PULL_REQUEST:-false}" != "false" || "${SBOM_GENERATE:-true}" == "false" || "${SBOM_UPLOAD:-true}" == "false" ]]; then
  echo "Skipping Dependency-Track uploads"
  exit 0
fi

: "${DEPENDENCY_TRACK_URL:?Set the DEPENDENCY_TRACK_URL secret}"
: "${DEPENDENCY_TRACK_API_KEY:?Set the DEPENDENCY_TRACK_API_KEY secret}"

SBOM_DIR=$(mktemp -d)
trap 'rm -rf "$SBOM_DIR"' EXIT
cd "$SBOM_DIR"

SERVICES=(
  archivematica-dashboard
  archivematica-mcp-client
  archivematica-mcp-server
  archivematica-storage-service
  archivematica-nginx
  clamavd
)

# Download the complete set from this build before updating any inventories.
for service in "${SERVICES[@]}"; do
  buildkite-agent artifact download "$service.cdx.json" .
  test -s "$service.cdx.json"
done

for service in "${SERVICES[@]}"; do
  echo "--- Uploading SBOM for $service"
  curl --fail-with-body --silent --show-error \
    --connect-timeout 10 --max-time 60 \
    "${DEPENDENCY_TRACK_URL%/}/api/v1/bom" \
    --header "X-Api-Key: $DEPENDENCY_TRACK_API_KEY" \
    --form-string "autoCreate=true" \
    --form-string "projectName=wellcomecollection/archivematica-infrastructure/$service" \
    --form-string "projectVersion=main" \
    --form-string "parentUUID=b49a7713-aa38-4260-8dcb-0d7c54627d5e" \
    --form "bom=@$service.cdx.json"
done
