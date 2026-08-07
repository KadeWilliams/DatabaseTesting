#!/bin/bash
# Starts SQL Server, waits for it to accept connections, then publishes the
# .dacpac baked into this image. sqlpackage's /Action:Publish is idempotent —
# on a brand-new database it creates the schema; on an existing one it
# generates and applies an upgrade script. Same entrypoint, same command,
# whether this is the first run or the hundredth.
set -euo pipefail

SQLCMD=/opt/mssql-tools18/bin/sqlcmd
if [ ! -x "$SQLCMD" ]; then
    SQLCMD=/opt/mssql-tools/bin/sqlcmd
fi

READY_MARKER=/tmp/schema-deployed
rm -f "$READY_MARKER"

/opt/mssql/bin/sqlservr &
SQLSERVR_PID=$!

trap 'echo "Shutting down..."; kill -TERM "$SQLSERVR_PID" 2>/dev/null; wait "$SQLSERVR_PID"' TERM INT

echo "Waiting for SQL Server to accept connections..."
for i in $(seq 1 60); do
    if "$SQLCMD" -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -N -Q "SELECT 1" > /dev/null 2>&1; then
        echo "SQL Server is up."
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "SQL Server did not become ready in time." >&2
        exit 1
    fi
    sleep 2
done

echo "Deploying schema from MyApplication.Database.dacpac to ${DATABASE_NAME}..."
sqlpackage \
    /Action:Publish \
    /SourceFile:/opt/db/MyApplication.Database.dacpac \
    /TargetServerName:localhost \
    /TargetDatabaseName:"${DATABASE_NAME}" \
    /TargetUser:sa \
    /TargetPassword:"${MSSQL_SA_PASSWORD}" \
    /TargetTrustServerCertificate:true

echo "Schema deployed. Database ready."

# docker-compose's healthcheck polls for this file rather than just
# re-running "SELECT 1" — SQL Server accepts connections well before the
# sqlpackage publish above finishes (measured ~7s vs ~20s on a cold start),
# so a connectivity-only healthcheck can report "healthy" while the schema
# and seed data are still being deployed, letting the web container start
# and hit stored procedures that don't exist yet.
touch "$READY_MARKER"

wait "$SQLSERVR_PID"