# Versioned database images

This is the idea from the original design discussion, implemented: **every
database image is a pull-able snapshot of the schema at a specific commit.**

## How it works here

`docker/Dockerfile.database` is a two-stage build:

1. The `build` stage compiles `MyApplication.Database.sqlproj` into a
   `.dacpac` — a single file that fully describes the schema (tables,
   indexes, foreign keys, views, stored procedures, post-deployment seed
   scripts).
2. The final stage bakes that `.dacpac` into a SQL Server image, along with
   `sqlpackage` and an entrypoint script (`docker/db-entrypoint.sh`) that
   deploys it the moment the container starts.

`sqlpackage /Action:Publish` is idempotent — against an empty database it
creates the schema from scratch; against an existing one it diffs and
generates an upgrade script. Same image, same command, whether it's a fresh
`docker compose up` or a container that's been running for months and just
got a new image.

Because the dacpac is baked in at build time, **the image itself is the
version**. Tag it, and you can pull that tag back later:

```
myapp-db:a3f92bc     # git short sha
myapp-db:v1.0.0      # or a friendly version, if you tag one
myapp-db:latest
```

## Building and tagging an image

```bash
scripts/build-db-image.sh            # tags myapp-db:<git-sha> and :latest
scripts/build-db-image.sh v1.1.0     # also tags myapp-db:v1.1.0
```

Do this once per commit that touches `src/MyApplication.Database/`, the same
way `.github/workflows/ci-cd.yml` does it in CI, and you get a running
history of every schema version the project has ever had — each one a plain
Docker image sitting in a registry.

## Pulling a version back and inspecting it

```bash
docker run -d --name myapp-db-old -p 1434:1433 \
  -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='YourStrong@Passw0rd' \
  myapp-db:v1.0.0

docker exec myapp-db-old /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong@Passw0rd' -C -N -d MyApplicationDb \
  -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES"
```

That's a real, queryable SQL Server instance running the exact schema from
that commit — not a diagram, not a migration log you have to read and
mentally replay.

## Comparing two versions directly

```bash
scripts/compare-schema.sh v1.0.0 v1.1.0 Order
```

This spins both images up on ephemeral containers, dumps a table's columns
from each, diffs them, and tears the containers down. It's the "what changed
between two weeks ago and now" question, answered in one command instead of
by reading migration files.

## Running a whole historical stack

`docker-compose.historical.yml` pairs a specific database image with a
specific web app image, on ports that don't collide with your normal
`docker compose up`:

```bash
DB_TAG=v1.0.0 WEB_TAG=v1.0.0 docker compose -f docker-compose.historical.yml up
```

Now `http://localhost:8081` is the application exactly as it existed at that
commit, talking to a database with that commit's schema, running alongside
your current stack on `http://localhost:8080`. Reproducing "what did this
look like before we made that change" becomes a single command instead of a
checkout-and-rebuild.

## What this repo demonstrates vs. what a real system would add

This repo covers **Phase 1** of the original plan: schema-only images,
tagged by commit, deployed idempotently. The seed data in
`Scripts/Post-Deployment/02_SeedSampleData.sql` is reference/demo data, so
this also gets you most of **Phase 2** (images that are immediately usable,
no manual setup) for free.

Not implemented here, but straightforward extensions if you wanted to go
further:

- **Phase 3 — full data snapshots.** Take a `.bak` backup after each deploy,
  store it in object storage (S3/Blob) keyed by git sha, and have the
  entrypoint script restore a specific backup at startup instead of just
  deploying the empty schema. Keeps images small; makes "what did the *data*
  look like" reproducible too. Anonymize first if any of it is real
  production data — tools like [Bogus](https://github.com/bchavez/Bogus)
  generate realistic fake data with the right shape and referential
  integrity.
- **Phase 4 automation** — this repo's `docker-compose.historical.yml` is
  the Phase 4 mechanism already; a real pipeline would auto-generate one of
  these per deploy rather than you hand-editing tags.
