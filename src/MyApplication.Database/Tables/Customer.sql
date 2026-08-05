-- System-versioned temporal table: every UPDATE/DELETE automatically
-- archives the prior row version into CustomerHistory, with no application
-- code involved. This is a different kind of "history" than the versioned
-- Docker images elsewhere in this project — that answers "what did the
-- SCHEMA look like at commit X"; this answers "what did this ROW look like
-- at time X". See docs/production-playbook.md.
CREATE TABLE [dbo].[Customer]
(
    [CustomerId]   INT             NOT NULL IDENTITY(1,1),
    [FirstName]    NVARCHAR(100)   NOT NULL,
    [LastName]     NVARCHAR(100)   NOT NULL,
    [Email]        NVARCHAR(256)   NOT NULL,
    [CreatedAtUtc] DATETIME2(0)    NOT NULL CONSTRAINT [DF_Customer_CreatedAtUtc] DEFAULT (SYSUTCDATETIME()),
    [ValidFrom]    DATETIME2       GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    [ValidTo]      DATETIME2       GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([CustomerId]),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[CustomerHistory]));
