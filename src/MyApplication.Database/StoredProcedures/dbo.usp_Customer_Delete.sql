CREATE PROCEDURE [dbo].[usp_Customer_Delete]
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM [dbo].[Customer]
    WHERE [CustomerId] = @CustomerId;
END
