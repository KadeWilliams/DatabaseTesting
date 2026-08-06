-- Target of Customer's SYSTEM_VERSIONING (see Customer.sql). Defined
-- explicitly, rather than letting SQL Server auto-generate it, so the
-- dacpac fully owns this table's shape and it can carry its own index
-- (IX_CustomerHistory_Id_ValidFrom) like any other project-managed object.
CREATE TABLE [dbo].[CustomerHistory]
(
    [CustomerId]   INT             NOT NULL,
    [FirstName]    NVARCHAR(100)   NOT NULL,
    [LastName]     NVARCHAR(100)   NOT NULL,
    [Email]        NVARCHAR(256)   NOT NULL,
    [CreatedAtUtc] DATETIME2(0)    NOT NULL,
    [ValidFrom]    DATETIME2       NOT NULL,
    [ValidTo]      DATETIME2       NOT NULL
);
