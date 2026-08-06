CREATE PROCEDURE [dbo].[usp_Customer_GetById]
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [CustomerId], [FirstName], [LastName]
    FROM [dbo].[Customer]
    WHERE [CustomerId] = @CustomerId;
END
