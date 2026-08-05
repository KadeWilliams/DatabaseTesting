CREATE PROCEDURE [dbo].[usp_Order_Insert]
    @CustomerId INT,
    @StatusId   INT,
    @Notes      NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[Order] ([CustomerId], [StatusId], [Notes])
    VALUES (@CustomerId, @StatusId, @Notes);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS [OrderId];
END
