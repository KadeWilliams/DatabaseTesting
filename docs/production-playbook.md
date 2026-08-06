# Production playbook

This doc exists because the rest of this repo shows the *mechanism* —
`docker compose up` and you have a working schema + app. That's deliberately
the easy part. This is the "okay, but how does this actually get used by a
small team with no DBA, no ops group, and change control that's basically
'someone reviewed the PR'" part.

If you haven't read them yet, `docs/versioned-db-images.md` (schema-as-a-
Docker-image) and this doc are meant to be read together — that one covers
the mechanics, this one covers the judgment calls.

## Your actual constraints, stated plainly

- No dedicated DBA or deployment/ops group. Whatever safety net exists has
  to come from tooling, not a person double-checking things.
- No HA/DR, no clusters. Small team, real customer data, limited time to
  spend on infrastructure ceremony.
- Change control is code review. That's it. That's the gate.
- Azure DevOps Repos/Pipelines at work, not GitHub — the *ideas* here are
  platform-agnostic (it's still just git), but the automation examples in
  this repo are GitHub Actions since that's what this repo runs on. See
  `docs/azure-pipelines-schema-diff.yml` for the ADO translation.

Everything below is written for that reality, not for an enterprise with a
platform team. A lot of "how to do this properly" advice online assumes
resources you don't have — the goal here is the smallest set of practices
that actually substitute for the roles/process you're missing, not the
biggest set that a Fortune 500 IT department would use.

## Why a Database Project instead of (or alongside) EF Core migrations

Short version, longer version was covered in conversation: a `.sqlproj` is
**declarative** — you describe the desired end state in `.sql` files, and
`sqlpackage` diffs that against whatever a target database actually looks
like and generates the delta. EF Core migrations are **imperative** — a
sequence of C#-generated Up/Down steps applied in order. The declarative
model is a better fit here specifically because:

- **It doesn't require a DBA to review.** Schema changes are just files in
  a PR, reviewed the same way as any other diff. That's the actual
  replacement for a missing DBA function — not a person, a workflow.
- **Build-time validation.** A stored procedure referencing a column that
  got renamed fails `dotnet build`, in CI, on the PR — not at 2am during a
  deploy. This project's stored-procedure-only data access pattern
  (`src/MyApplication.Infrastructure/Repositories/`) only works because the
  database project can validate that every proc actually compiles against
  the current table shapes.
- **It produces a portable artifact** (the `.dacpac`) that can be versioned,
  diffed, and baked into a Docker image — none of which is true of EF's
  migration history, which is C# code that runs against a live connection.

If you're also using EF Core or plan to: don't let both EF migrations and
the Database Project try to own schema state at the same time. Pick one.
The clean combination is **Database Project owns schema; EF (if used at
all) runs with migrations disabled, scaffolded from the dacpac, purely as
a query/mapping convenience** — same as how Dapper is used in this repo,
just a different data-access library pointed at the same stored procedures
and tables.

## How a schema change actually reaches a real environment

This is the piece that's easy to miss because the Docker demo does it
automatically at container startup. Strip that away and it's one command:

```bash
sqlpackage /Action:Publish \
  /SourceFile:MyApplication.Database.dacpac \
  /TargetConnectionString:"<real connection string>"
```

`sqlpackage` connects to whatever that connection string points at,
compares the target's actual current schema against what the dacpac says
it should be, generates a script for just the delta, and runs it. Same
dacpac, same command, whether the target is brand new, five versions
behind, or already current.

Two ways to invoke it:

- **`/Action:Script`** generates the delta as a `.sql` file *without*
  running it — a reviewable artifact. This is what the PR diff-preview
  workflow below uses.
- **`/Action:Publish`** generates and immediately executes it. This is what
  a real deploy step does, pointed at dev/staging/prod via a connection
  string held as a pipeline secret per environment.

`docker/db-entrypoint.sh` in this repo is a worked example of `/Action:Publish`
— it's just pointed at `localhost` inside a throwaway container instead of
a real database. A production deploy step is actually *shorter*, since it
doesn't need to also boot a fresh SQL Server first.

## What's local-dev-only vs. what's real

Everything in `docker/` is a legitimate mechanism, but not all of it is
meant to run as-is in production:

| In this repo | In production |
|---|---|
| `sa` login, plaintext password in compose | Least-privilege login scoped to `EXECUTE` on specific procs only; secret from a vault, not a file |
| SQL Server *container* as the database | A managed service (Azure SQL Database, RDS for SQL Server) — see below |
| Ports published to the host | No direct database exposure; app-only connectivity |
| `docker compose up` | Whatever your actual app hosting is (App Service, Container Apps, ECS, etc.) |

**The database container itself is a dev/CI tool, not a production
runtime.** Its actual production job is narrower than "be the database" —
it's "prove the dacpac deploys cleanly," which is exactly what the
`schema-diff` job below does in CI. In production, you still run
`sqlpackage /Action:Publish`, you just point it at a managed database
instance instead of a container.

**If you're not already on a managed database service, that's the single
highest-leverage move available to you.** It outsources backups,
point-in-time restore, and patching — the things a DBA team would
otherwise own — to the cloud provider, for close to zero ongoing effort.
Given "real customer data, no ops group," this isn't optional ceremony,
it's the cheapest insurance you can buy.

## The stale-branch problem, and what actually protects you

The scenario: a branch sits open for weeks. Meanwhile someone else merges a
PR that changes a table your branch also touches. If your branch's copy of
that table's `.sql` file is out of date when its dacpac gets built and
published, `sqlpackage` doesn't know your copy is stale — it just sees "the
desired state of this table is what's in this dacpac," which might mean
generating a script that **drops a column someone else added** while you
were away.

Three things blunt this, in order of how much they actually help:

1. **Rebase/merge main into long-lived branches periodically**, not just
   once at the end. Since the schema lives in plain-text `.sql` files, git
   handles this exactly like any other merge — conflicting edits to the
   same table show up as a normal merge conflict, not a silent surprise.
2. **`BlockOnPossibleDataLoss` (on by default) is the automated fallback**
   if you forget. `sqlpackage` refuses to publish a change that would drop
   a populated column/table rather than doing it silently. Worst case with
   a genuinely stale branch: the deploy step fails loudly, someone rebases,
   tries again. Not "production silently lost data."
3. **The PR schema-diff workflow (next section) makes the danger visible
   at review time**, before merge, instead of discovering it when a deploy
   step fails or — worse — succeeds when it shouldn't have.

## Automated PR schema diff preview

`.github/workflows/pr-schema-diff.yml` in this repo (triggered on
`pull_request`, scoped to changes under `src/MyApplication.Database/`)
answers "what would merging this PR actually do to the schema" *before*
merge, the same way `terraform plan` shows infrastructure changes before
`apply`.

What it does:

1. Builds two `.dacpac`s: one from the PR branch, one from the PR's base
   branch (i.e., what's about to be the new baseline).
2. Publishes the base branch's dacpac into a throwaway SQL Server service
   container — a stand-in for "the schema this PR is being compared
   against."
3. Runs `sqlpackage /Action:Script` to generate (not execute) the script
   that would take that baseline to the PR's schema.
4. Posts the generated script as a sticky PR comment (updated in place on
   each push, not spammed as a new comment every time), plus uploads it as
   a build artifact.

**Why diff against the base branch's freshly-built dacpac instead of the
real target database directly:** it means zero real credentials are needed
in PR CI. As long as you're doing deploy-on-merge (so `main` stays a close
proxy for what's actually live), this is accurate without the exposure of
handing every PR pipeline a connection string to staging or prod. If that
assumption ever stops holding, this can graduate to a read-only,
schema-only credential against the real environment — not a day-one
requirement.

**Why this isn't an auto-blocking check on content:** the job succeeding
(dacpac builds, diff generates cleanly) is worth making a required check.
Whether the diff *contains* a `DROP` is not — that's often the intended
change, and a keyword-based hard block just trains people to find ways
around it. The goal is *visibility a reviewer can't miss*, not an
automatic veto.

**This already caught a real bug while building this repo.** Adding the
`Customer` temporal table (see below) initially generated hidden period
columns with no default value. Diffing the PR against a baseline that
already had `Customer` rows produced:

```
IF EXISTS (select top 1 1 from [dbo].[Customer])
    RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT
```

i.e., `sqlpackage` would have refused to deploy this against any database
with real customers in it. The fix was adding explicit `DEFAULT` values to
the period columns (see `src/MyApplication.Database/Tables/Customer.sql`)
— exactly the kind of thing you want caught by a diff on a PR, not by a
failed deploy at 2am with nobody watching.

**Azure DevOps version:** `docs/azure-pipelines-schema-diff.yml` is the
same idea translated to Azure Pipelines YAML + the ADO REST API for posting
the comment. It hasn't been run against a real ADO org (unlike the GitHub
version, which was built by verifying every individual `sqlpackage`/`dotnet`
command against real containers) — treat it as a strong starting point that
needs your project's actual names/paths, not a tested drop-in.

## Temporal tables: a different axis of "history"

`Customer` is a SQL Server system-versioned temporal table
(`src/MyApplication.Database/Tables/Customer.sql` +
`CustomerHistory.sql`). Every `UPDATE`/`DELETE` automatically archives the
prior row version — no application code writes these rows, the engine does
it. Query the full history through `dbo.usp_Customer_GetHistory`, which
uses `FOR SYSTEM_TIME ALL`.

Worth being explicit that this solves a **different problem** than the
versioned Docker images described in `docs/versioned-db-images.md`, even
though both involve the word "history":

- **Versioned db images** answer: "what did the *schema* look like at
  commit X" — structural history, at the granularity of a deploy.
- **Temporal tables** answer: "what did this *row* look like at time X" —
  data history, at the granularity of a single update.

You'll want both if you're the kind of team that gets "why does this
customer's order history look different than what support saw yesterday"
questions. If you don't get those questions, temporal tables on a handful
of tables that matter (this repo does it for `Customer`; extending to
`Order` for a status-change timeline is the same pattern) is a
low-effort, high-leverage way to stop having to guess.

## Anonymized data for local dev

The idea: a scheduled job pulls a prod backup, restores it to a scrubbing
instance, replaces anything sensitive, and republishes the scrubbed backup
somewhere `db-entrypoint.sh` can restore it from at container startup — so
every developer gets their own realistic, collision-free, PII-free copy of
real data with `docker compose up`. Practical split on scrubbing:

- **Free-text fields (`Notes`, `Comments`, anything unstructured):**
  overwrite with lorem ipsum, full stop. This is where PII most often ends
  up by accident — someone typed a real customer's name into a support
  note — and there's no safer option than "there is no real content left
  at all."
- **Structured fields with format/uniqueness requirements (`Email`,
  `Phone`, names shown in the UI):** need *some* realism — a `UNIQUE`
  constraint on `Email` won't tolerate every row being identical, and a
  UI full of "Lorem Ipsum" as every customer name makes local dev harder
  to actually use for eyeballing whether something looks right. [Bogus](https://github.com/bchavez/Bogus)
  generates plausible-but-fake data for exactly this case.

Don't spend the "realistic fake data" effort on fields where content never
matters — that's where lorem ipsum is strictly better, not just simpler.

## Suggested adoption order

Don't do all of this at once. In order of "how much value for how little
disruption":

1. **Model the current schema in a `.sqlproj`, change nothing else about
   how deploys happen.** Reverse-engineer it from the live database (Azure
   Data Studio / SSMS schema-compare tooling does this). You don't need
   every object — `DropObjectsNotInSource` defaults to `False`, so objects
   you haven't modeled are left alone when you publish. Schema changes
   become PR-reviewable immediately; nothing about deployment changes yet.
2. **Add the PR schema-diff check.** Now every PR shows its actual schema
   impact before merge, for the cost of one CI job.
3. **Wire `sqlpackage /Action:Publish` into your real deploy pipeline**,
   gated on the PR being merged and the build succeeding. This is the
   actual automation moment — schema deploys become as automatic as app
   deploys.
4. **Move to a managed database service**, if not already there, for the
   backup/DR coverage a DBA team would otherwise provide.
5. **Temporal tables on the handful of tables where "what did this look
   like before" is a recurring question.** Optional, additive, cheap once
   the rest is in place.
6. **Anonymized-prod-in-a-container for local dev.** Nice-to-have, biggest
   effort of this list (needs a scheduled scrub-and-republish job), lowest
   urgency — do it once 1–3 feel routine.

Everything past step 1 is additive. Step 1 alone gets you most of the real
risk reduction (reviewable schema changes, build-time validation) for the
least upheaval, which matters more than usual given there's no dedicated
person whose job is to absorb that upheaval.
