CREATE PROCEDURE [dbo].[usp_OrderLineItem_Insert]
    @OrderId     INT,
    @ProductName NVARCHAR(200),
    @Quantity    INT,
    @UnitPrice   DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[OrderLineItem] ([OrderId], [ProductName], [Quantity], [UnitPrice])
    VALUES (@OrderId, @ProductName, @Quantity, @UnitPrice);
END
