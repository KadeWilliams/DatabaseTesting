CREATE PROCEDURE [dbo].[usp_Order_UpdateStatus]
    @OrderId  INT,
    @StatusId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [dbo].[Order]
    SET [StatusId] = @StatusId
    WHERE [OrderId] = @OrderId;
END
