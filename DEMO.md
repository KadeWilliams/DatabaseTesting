# Demo script

A runbook for actually showing this off — to yourself, or to other people.
Everything here runs entirely on Docker, locally. Nothing touches your real
SQL Server environment; that's the point.

Budget ~15 minutes for the full walkthrough, or pick individual parts.
Each part stands alone if you're short on time.

---

## Setup (do this before anyone's watching)

```bash
git clone <this repo> && cd DatabaseTesting
docker compose up --build
```

First run takes a couple of minutes — it's building three images (SQL
project → `.dacpac`, the database image, the web image), then SQL Server
has to boot before the schema deploy runs. Get this running *before* the
demo starts; the build itself isn't the interesting part.

Once it's up: **http://localhost:8080**

Also pre-build the two version images used in Part 5, so that part is a
live comparison instead of a live build wait:

```bash
git checkout v1.0.0 && scripts/build-db-image.sh v1.0.0
git checkout v1.1.0 && scripts/build-db-image.sh v1.1.0
git checkout claude/docker-database-projects-demo-nd0k6i   # back to the branch tip
```

---

## Part 1 — "It's just one command"

**Say:** "This spins up a real SQL Server instance, deploys the actual
production schema into it, seeds it with data, and starts the app — all
from a clean clone, one command."

```bash
docker compose logs db | tail -40
```

**Show:** the deploy log — `Creating Table [dbo].[Customer]...`,
`Creating Procedure...`, `Successfully published database.` This is
`sqlpackage` deploying the same `.dacpac` that CI builds and that would
deploy to a real environment — the only thing different in production is
what connection string it's pointed at.

---

## Part 2 — The app, and what's actually backing it

Open **http://localhost:8080/Customers**, **Orders**, click into a customer,
create an order.

**Say:** "None of this app code talks to a table directly." Open
`src/MyApplication.Infrastructure/Repositories/CustomerRepository.cs` —
every call goes through a named stored procedure
(`dbo.usp_Customer_GetById`, etc.). The stored procedures are the actual
contract between the app and the database — swap the app's language
entirely and the procs don't care.

---

## Part 3 — The schema is just code

Open `src/MyApplication.Database/` in an editor.

**Say:** "This is a normal buildable project, not a folder of scripts
someone runs by hand."

```bash
docker run --rm -v "$PWD":/src -w /src/src/MyApplication.Database \
  mcr.microsoft.com/dotnet/sdk:8.0 dotnet build MyApplication.Database.sqlproj
```

**Show:** it builds like any other project — `dotnet build`, zero errors,
produces a `.dacpac`. Point out `Tables/`, `StoredProcedures/`,
`Views/`, `Indexes/` — every schema object is a reviewable file. A broken
reference (a proc pointing at a column that got renamed) fails **this
build**, not a deploy.

---

## Part 4 — Temporal tables: history with zero application code

This is the one that tends to land best live, because it looks like magic
and isn't.

```bash
# Edit a customer a couple of times through the running app —
# or via sqlcmd directly:
docker compose exec db /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong@Passw0rd' -C -N -d MyApplicationDb \
  -Q "EXEC dbo.usp_Customer_Update @CustomerId=1, @FirstName=N'Ada', @LastName=N'Byron', @Email=N'ada.lovelace@example.com'"

docker compose exec db /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong@Passw0rd' -C -N -d MyApplicationDb \
  -Q "EXEC dbo.usp_Customer_Update @CustomerId=1, @FirstName=N'Ada', @LastName=N'Lovelace', @Email=N'ada.lovelace@example.com'"

# Now pull the full history:
docker compose exec db /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong@Passw0rd' -C -N -d MyApplicationDb \
  -Q "EXEC dbo.usp_Customer_GetHistory @CustomerId=1"
```

**Say:** "I never wrote a single line of code to record that history —
`Customer` is a SQL Server system-versioned temporal table. Every update
automatically archives the previous version into `CustomerHistory`, with
exact timestamps of when each version was valid." Point out this is a
*different* kind of history than the next part — this is "what did this
row look like," not "what did the schema look like."

---

## Part 5 — Time travel on the schema itself

```bash
scripts/compare-schema.sh v1.0.0 v1.1.0 Order
```

**Say:** "These are two real, buildable versions of this database sitting
in git history. Watch." **Show:** the script spins up both versions as
actual SQL Server containers and diffs the real `Order` table between
them:

```
=== [Order] columns: v1.0.0 vs v1.1.0 ===
+Priority tinyint NOT NULL
```

**Say:** "That's not a changelog someone wrote — that's two real database
containers being compared live. And it's not just additive — the same
image, deployed on top of `v1.0.0`'s actual data, performs a genuine
`ALTER TABLE`, not a drop-and-recreate. Existing rows survive." (This is
documented with the actual verified log output in
`docs/versioned-db-images.md` if you want to show the receipts without
re-running it live.)

---

## Part 6 — Catching a bad migration before it ships (optional, needs ~3 min + a real PR)

Skip this part if you're tight on time — it needs a real GitHub PR to
demonstrate live, or you can just narrate the story below instead.

**Live version:** make a trivial, deliberately risky schema edit —
e.g. add `[MiddleName] NVARCHAR(100) NOT NULL` (no default) to
`Tables/Customer.sql` — push it to a branch, open a PR. Within a couple of
minutes, `.github/workflows/pr-schema-diff.yml` posts a comment showing
the exact script that PR would run, including whatever red flags
`sqlpackage` raises.

**Narrated version (no live PR needed):** "This already caught a real bug
while I was building this. Adding the temporal columns to `Customer`
initially had no default value on the hidden period columns. The PR diff
generated this:"

```
IF EXISTS (select top 1 1 from [dbo].[Customer])
    RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT
```

"That's `sqlpackage` refusing to deploy against any database that actually
has customers in it — caught on the PR, not in production." Full story in
`docs/production-playbook.md`.

---

## Wrap-up talking points

- Nothing here required a DBA or a deployment team — the tooling
  substitutes for the process a bigger org would have a person do.
- Everything just shown runs the same way in CI (`.github/workflows/`) —
  this isn't a special local-only demo path.
- What changes for real production: the database container becomes a
  managed database service, the `sa` login becomes a scoped one, and
  `sqlpackage /Action:Publish` points at a real connection string instead
  of `localhost`. Same mechanism throughout — see
  `docs/production-playbook.md` for the full breakdown.

---

## Cleanup

```bash
docker compose down -v
```
