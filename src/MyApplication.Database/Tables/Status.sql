CREATE TABLE [dbo].[Status]
(
    [StatusId]   INT           NOT NULL IDENTITY(1,1),
    [Name]       NVARCHAR(50)  NOT NULL,
    [SortOrder]  INT           NOT NULL,
    CONSTRAINT [PK_Status] PRIMARY KEY CLUSTERED ([StatusId]),
    CONSTRAINT [UQ_Status_Name] UNIQUE ([Name])
);
