CREATE TABLE [dbo].[Customer]
(
    [CustomerId] INT           NOT NULL IDENTITY(1,1),
    [FirstName]  NVARCHAR(100) NOT NULL,
    [LastName]   NVARCHAR(100) NOT NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([CustomerId])
);
