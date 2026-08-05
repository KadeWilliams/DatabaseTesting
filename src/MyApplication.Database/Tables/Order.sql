CREATE TABLE [dbo].[Order]
(
    [OrderId]      INT             NOT NULL IDENTITY(1,1),
    [CustomerId]   INT             NOT NULL,
    [StatusId]     INT             NOT NULL,
    [OrderDate]    DATETIME2(0)    NOT NULL CONSTRAINT [DF_Order_OrderDate] DEFAULT (SYSUTCDATETIME()),
    [Notes]        NVARCHAR(400)   NULL,
    [Priority]     TINYINT         NOT NULL CONSTRAINT [DF_Order_Priority] DEFAULT (0),
    CONSTRAINT [PK_Order] PRIMARY KEY CLUSTERED ([OrderId]),
    CONSTRAINT [FK_Order_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_Order_Status] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[Status] ([StatusId])
);
