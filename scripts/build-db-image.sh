#!/bin/bash
# Builds the database schema image and tags it with a specific version.
# This tagged image IS the artifact that gets promoted — build it once here,
# then point docker-compose.promotion.yml at the same tag for every
# environment. No environment ever gets its own build.
#
# Usage: scripts/build-db-image.sh <version>
# Example: scripts/build-db-image.sh v1.0.0
set -euo pipefail

VERSION="${1:?Usage: scripts/build-db-image.sh <version>}"
IMAGE="myapp-db:${VERSION}"

docker build \
    -f docker/Dockerfile.database \
    -t "${IMAGE}" \
    --build-arg SCHEMA_VERSION="${VERSION}" \
    .

echo "Built ${IMAGE}"
