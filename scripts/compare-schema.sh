#!/usr/bin/env bash
# The "time travel" demo: spins up two versions of the database image side
# by side and diffs a table's columns between them. This is the payoff of
# tagging db images by git sha — you can literally pull the schema as it
# existed at two different points in history and compare them, no manual
# archaeology through migration scripts required.
#
# Usage:
#   scripts/compare-schema.sh <tag-a> <tag-b> [table-name]
#
# Example:
#   scripts/compare-schema.sh v1.0.0 v1.1.0 Order
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <tag-a> <tag-b> [table-name]" >&2
    exit 1
fi

TAG_A="$1"
TAG_B="$2"
TABLE="${3:-Order}"
PASSWORD="YourStrong@Passw0rd"

CONTAINER_A="schema-compare-a-$$"
CONTAINER_B="schema-compare-b-$$"

cleanup() {
    docker rm -f "$CONTAINER_A" "$CONTAINER_B" > /dev/null 2>&1 || true
}
trap cleanup EXIT

wait_ready() {
    local container="$1"
    # Poll the target database itself (not just the SQL Server engine) —
    # sqlpackage creates the database in the first second of a publish, long
    # before the schema and post-deployment seed finish, so we wait for the
    # seed data specifically to know the whole deploy is actually done.
    for _ in $(seq 1 60); do
        local count
        count=$(docker exec "$container" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$PASSWORD" -C -N -d MyApplicationDb -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.Status" 2>/dev/null | tr -d '[:space:]') || true
        if [ "${count:-0}" -gt 0 ] 2>/dev/null; then
            return 0
        fi
        sleep 2
    done
    echo "Timed out waiting for $container to become ready." >&2
    docker logs --tail 40 "$container" >&2
    exit 1
}

dump_columns() {
    local container="$1"
    docker exec "$container" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$PASSWORD" -C -N -d MyApplicationDb -h -1 -Q \
        "SET NOCOUNT ON; SELECT COLUMN_NAME + ' ' + DATA_TYPE + ISNULL('(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ')', '') + CASE WHEN IS_NULLABLE = 'YES' THEN ' NULL' ELSE ' NOT NULL' END FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TABLE' ORDER BY ORDINAL_POSITION;"
}

echo "Starting myapp-db:${TAG_A} ..."
docker run -d --name "$CONTAINER_A" -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD="$PASSWORD" "myapp-db:${TAG_A}" > /dev/null

echo "Starting myapp-db:${TAG_B} ..."
docker run -d --name "$CONTAINER_B" -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD="$PASSWORD" "myapp-db:${TAG_B}" > /dev/null

wait_ready "$CONTAINER_A"
wait_ready "$CONTAINER_B"

dump_columns "$CONTAINER_A" > /tmp/schema-${TAG_A//\//_}.txt
dump_columns "$CONTAINER_B" > /tmp/schema-${TAG_B//\//_}.txt

echo
echo "=== [$TABLE] columns: ${TAG_A} vs ${TAG_B} ==="
if diff --unified=0 --label "${TAG_A}" --label "${TAG_B}" \
    /tmp/schema-${TAG_A//\//_}.txt /tmp/schema-${TAG_B//\//_}.txt; then
    echo "(no differences)"
fi

exit 0
