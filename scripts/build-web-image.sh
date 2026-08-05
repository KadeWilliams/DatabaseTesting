#!/usr/bin/env bash
# Same idea as build-db-image.sh, but for the web app. Tagging both images
# with the same git sha is what makes docker-compose.historical.yml able to
# pin a matched API+schema pair from any point in the project's history.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

SHA="$(git rev-parse --short HEAD)"
DIRTY=""
if ! git diff --quiet || ! git diff --cached --quiet; then
    DIRTY="-dirty"
fi
APP_VERSION="${SHA}${DIRTY}"

echo "Building myapp-web:${APP_VERSION} ..."
docker build \
    -f docker/Dockerfile.web \
    --build-arg APP_VERSION="${APP_VERSION}" \
    -t "myapp-web:${APP_VERSION}" \
    -t "myapp-web:latest" \
    .

if [ -n "${1:-}" ]; then
    docker tag "myapp-web:${APP_VERSION}" "myapp-web:$1"
    echo "Also tagged myapp-web:$1"
fi

echo
echo "Images:"
docker images myapp-web --format '  {{.Repository}}:{{.Tag}}  ({{.Size}}, built {{.CreatedSince}})'
