CREATE PROCEDURE [dbo].[usp_GetAllCustomers]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [CustomerId], [FirstName], [LastName]
    FROM [dbo].[Customer];
END
