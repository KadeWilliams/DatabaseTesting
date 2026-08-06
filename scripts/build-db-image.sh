#!/usr/bin/env bash
# Builds the database image and tags it with the current git commit (and
# optionally a friendly version like v1.2.0). Because the image bundles the
# .dacpac built from whatever the SQL project looked like at that commit,
# every tag you push is a pull-able snapshot of the schema at that point in
# history — see docs/versioned-db-images.md.
#
# Usage:
#   scripts/build-db-image.sh [friendly-version]
#
# Examples:
#   scripts/build-db-image.sh              # tags with git sha only
#   scripts/build-db-image.sh v1.1.0        # also tags myapp-db:v1.1.0
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SHA="$(git rev-parse --short HEAD)"
DIRTY=""
if ! git diff --quiet || ! git diff --cached --quiet; then
    DIRTY="-dirty"
fi
SCHEMA_VERSION="${SHA}${DIRTY}"

echo "Building myapp-db:${SCHEMA_VERSION} ..."
docker build \
    -f docker/Dockerfile.database \
    --build-arg SCHEMA_VERSION="${SCHEMA_VERSION}" \
    -t "myapp-db:${SCHEMA_VERSION}" \
    -t "myapp-db:latest" \
    .

if [ -n "${1:-}" ]; then
    docker tag "myapp-db:${SCHEMA_VERSION}" "myapp-db:$1"
    echo "Also tagged myapp-db:$1"
fi

echo
echo "Images:"
docker images myapp-db --format '  {{.Repository}}:{{.Tag}}  ({{.Size}}, built {{.CreatedSince}})'
