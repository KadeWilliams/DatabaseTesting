CREATE PROCEDURE [dbo].[usp_Customer_Delete]
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- comment to test
    DELETE FROM [dbo].[Customer]
    WHERE [CustomerId] = @CustomerId;
END
