# Command reference

Every command we've actually run in this exercise, grouped by what it's for,
with what each flag means and what it actually did for us — not just a bare
cheat sheet. Update this as we go if new ones come up.

## Building the database project (.NET / dotnet CLI)

```bash
dotnet new sln -n MyApplication
```
Creates a solution file (`MyApplication.sln`) — an empty shell that projects
get added to. We ran this once, at the very start of wrapping the database
project in a real solution.

```bash
dotnet sln add src/MyApplication.Database/MyApplication.Database.sqlproj
```
Adds a project to the solution file above. `dotnet sln` manages the `.sln`
file itself; this doesn't touch the project's own files at all, just
registers it as a member of the solution.

```bash
dotnet build MyApplication.sln -c Release
```
Compiles everything in the solution. For the database project specifically,
"compiling" means: parse every `.sql` file, build the schema model we looked
at in step 1 (`model.xml`), validate every reference (this is what caught
the `MiddleName` typo and the double-primary-key mistake), and if everything
checks out, zip it into a `.dacpac`. `-c Release` picks the build
configuration (vs. `Debug`) — doesn't matter much for a database project
specifically, but it's the standard flag across all .NET builds.

## Building the Docker image

```bash
docker build -f docker/Dockerfile -t test .
```
Builds an image from a `Dockerfile`.
- `-f docker/Dockerfile` — which Dockerfile to read instructions from. Needed
  here because ours isn't named `Dockerfile` sitting in the current folder —
  it's a level down, in `docker/`. Without `-f`, Docker only ever looks for
  a file literally named `Dockerfile` in the build context root.
- `-t test` — tags the resulting image with a name (`test`) so we can refer
  to it later instead of a random ID.
- `.` — the **build context**: which files on disk Docker's allowed to
  `COPY` into the image while building. Separate concept from `-f` — this
  says "you can reach into the whole repo," `-f` says "but read your
  instructions from this specific file."

This is what actually ran our multi-stage build: compiled the `.dacpac`
inside a throwaway SDK container (stage 1), then baked it into a real SQL
Server image alongside `sqlpackage` and the entrypoint script (stage 2).

## Running and managing containers

```bash
docker run -d --name customerdb -p 1433:1433 -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD='YourStrong@Passw0rd' test
```
Starts an actual running container from the `test` image.
- `-d` — "detached," runs in the background instead of tying up the terminal.
- `--name customerdb` — a friendly name instead of a random one Docker would
  otherwise generate.
- `-p 1433:1433` — publishes the container's port 1433 (SQL Server's default
  port) to the same port on your actual machine, so a GUI client (Azure Data
  Studio, DBeaver) could connect to `localhost,1433` from outside Docker
  entirely, not just from inside the container.
- `-e ACCEPT_EULA=Y` / `-e MSSQL_SA_PASSWORD=...` — environment variables the
  entrypoint script reads (remember `set -u` — the script errors out if
  `$MSSQL_SA_PASSWORD` isn't set, so this isn't optional).

This is the command that actually triggered our entrypoint script to run:
boot SQL Server, wait for it, deploy the schema, and (thanks to `wait
$SQLSERVR_PID` at the end of the script) keep running afterward instead of
exiting.

```bash
docker ps
```
Lists currently *running* containers. Used this to confirm `customerdb`
actually started successfully after the arm64/amd64 emulation warning —
if it shows up here, it's genuinely running, warning or not.

```bash
docker images
```
Lists every image Docker knows about — the ground-truth list, independent
of whatever Docker Desktop's GUI happens to be displaying. We used this to
confirm the `test` image genuinely existed after Docker Desktop's Images
tab wasn't showing it (a GUI refresh quirk, not a real problem).

```bash
docker logs -f customerdb
```
Streams a running container's output. `-f` follows it live (like `tail -f`)
instead of just dumping what's already happened and exiting. This is how
we watched our own entrypoint script's `echo` lines happen in real time —
"Waiting for SQL Server...", "SQL Server is up.", "Deploying schema...".

```bash
docker stop customerdb
docker rm customerdb
```
`stop` shuts a running container down (sends the TERM signal our `trap`
line in the entrypoint script handles); `rm` deletes a stopped container
entirely so the name is free to reuse. `docker rm -f <name>` does both at
once — force-stops and removes in one command. Haven't needed these yet
since we've been leaving `customerdb` running between sessions, but you'll
want them once you're cycling through containers more.

## Running commands inside a container

```bash
docker exec -it customerdb /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd' -C -N
```
`docker exec` runs a command *inside* an already-running container — different
from `docker run`, which starts a brand new container. `-it` makes it
interactive (`-i` keeps input open, `-t` gives you a proper terminal), which
is what let this drop us into a live `sqlcmd` prompt instead of just running
one query and exiting.

`sqlcmd`'s own flags: `-S localhost` (server — `localhost` because from
*inside* the container, SQL Server really is running on its own localhost),
`-U sa` / `-P ...` (login), `-C` (trust the self-signed cert SQL Server
generates for itself — fine for local dev, not something you'd do against a
real cert-bearing server), `-N` (encrypt the connection).

Once connected, this is what we actually ran:
```sql
USE MyApplicationDb;
GO

EXEC dbo.usp_InsertCustomer @FirstName=N'Ada', @LastName=N'Lovelace', @CreatedBy=N'me';
GO

UPDATE dbo.Customer SET LastName = N'Byron' WHERE CustomerId = 1;
GO

SELECT CustomerId, FirstName, LastName, CreatedBy, UpdatedBy, ValidFrom, ValidTo
FROM dbo.Customer FOR SYSTEM_TIME ALL
WHERE CustomerId = 1
ORDER BY ValidFrom;
GO
```
That last query is the one that proved temporal versioning actually works —
two rows came back for the same `CustomerId`, each with its own
`ValidFrom`/`ValidTo`. (First attempt used `SELECT *` and only showed 5
columns — `ValidFrom`/`ValidTo` are declared `HIDDEN`, so they're excluded
from `SELECT *` on purpose and have to be named explicitly.)
