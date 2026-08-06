CREATE TABLE [dbo].[OrderLineItem]
(
    [OrderLineItemId] INT             NOT NULL IDENTITY(1,1),
    [OrderId]         INT             NOT NULL,
    [ProductName]     NVARCHAR(200)   NOT NULL,
    [Quantity]        INT             NOT NULL,
    [UnitPrice]       DECIMAL(10,2)   NOT NULL,
    CONSTRAINT [PK_OrderLineItem] PRIMARY KEY CLUSTERED ([OrderLineItemId]),
    CONSTRAINT [FK_OrderLineItem_Order] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Order] ([OrderId]) ON DELETE CASCADE,
    CONSTRAINT [CK_OrderLineItem_Quantity] CHECK ([Quantity] > 0),
    CONSTRAINT [CK_OrderLineItem_UnitPrice] CHECK ([UnitPrice] >= 0)
);
