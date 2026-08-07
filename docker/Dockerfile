# syntax=docker/dockerfile:1
#
# Builds the schema-as-an-image: compiles the SQL Database Project into a
# .dacpac, then bakes that dacpac into a SQL Server image alongside SqlPackage
# and a startup script that deploys it. The resulting image IS a specific
# version of the schema — tag it (git sha, semver, date) and you can pull
# that exact schema back at any point in the future. See
# scripts/build-db-image.sh for how images get tagged.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR ../src
COPY src/MyApplication.Database/ ./MyApplication.Database/
RUN dotnet build ./MyApplication.Database/MyApplication.Database.sqlproj \
    -c Release \
    -o /out

FROM mcr.microsoft.com/mssql/server:2022-latest
USER root

ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer
ENV DATABASE_NAME=MyApplicationDb
ENV DOTNET_TOOLS_PATH=/opt/dotnet-tools
ENV PATH="${DOTNET_TOOLS_PATH}:${PATH}"

# SqlPackage is a .NET tool, so it needs a .NET runtime alongside it — pull
# both from Microsoft's package feed, deploy dacpacs, then drop the apt
# cache so the tooling doesn't linger in the image any larger than it has to.
# The SDK is only needed to install the sqlpackage tool itself; it's purged
# afterwards and only the runtime is left behind for sqlpackage to run on.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
    && curl -sSL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends dotnet-sdk-8.0 dotnet-runtime-8.0 \
    && dotnet tool install --tool-path "${DOTNET_TOOLS_PATH}" microsoft.sqlpackage \
    && apt-get purge -y curl gnupg dotnet-sdk-8.0 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/MyApplication.Database.dacpac /opt/db/MyApplication.Database.dacpac
COPY docker/db-entrypoint.sh /opt/db/db-entrypoint.sh
RUN chmod +x /opt/db/db-entrypoint.sh

# Label the image with what schema version it carries, so `docker inspect`
# tells you what you're looking at without having to spin it up first.
ARG SCHEMA_VERSION=dev
LABEL org.opencontainers.image.title="MyApplication database schema" \
      org.opencontainers.image.description="SQL Server 2022 + schema deployed from MyApplication.Database.dacpac" \
      myapplication.schema-version="${SCHEMA_VERSION}"

USER mssql
ENTRYPOINT ["/opt/db/db-entrypoint.sh"]