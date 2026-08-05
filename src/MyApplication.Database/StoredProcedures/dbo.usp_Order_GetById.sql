CREATE PROCEDURE [dbo].[usp_Order_GetById]
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.[OrderId],
        o.[CustomerId],
        c.[FirstName],
        c.[LastName],
        o.[StatusId],
        s.[Name] AS [StatusName],
        o.[OrderDate],
        o.[Notes]
    FROM [dbo].[Order] AS o
    INNER JOIN [dbo].[Customer] AS c ON c.[CustomerId] = o.[CustomerId]
    INNER JOIN [dbo].[Status] AS s ON s.[StatusId] = o.[StatusId]
    WHERE o.[OrderId] = @OrderId;

    SELECT [OrderLineItemId], [OrderId], [ProductName], [Quantity], [UnitPrice]
    FROM [dbo].[OrderLineItem]
    WHERE [OrderId] = @OrderId;
END
