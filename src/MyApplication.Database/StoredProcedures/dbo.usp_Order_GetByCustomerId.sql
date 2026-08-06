CREATE PROCEDURE [dbo].[usp_Order_GetByCustomerId]
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.[OrderId],
        o.[CustomerId],
        o.[StatusId],
        s.[Name] AS [StatusName],
        o.[OrderDate],
        o.[Notes],
        ISNULL(li.[OrderTotal], 0) AS [OrderTotal]
    FROM [dbo].[Order] AS o
    INNER JOIN [dbo].[Status] AS s ON s.[StatusId] = o.[StatusId]
    OUTER APPLY (
        SELECT SUM(oli.[Quantity] * oli.[UnitPrice]) AS [OrderTotal]
        FROM [dbo].[OrderLineItem] AS oli
        WHERE oli.[OrderId] = o.[OrderId]
    ) AS li
    WHERE o.[CustomerId] = @CustomerId
    ORDER BY o.[OrderDate] DESC;
END
