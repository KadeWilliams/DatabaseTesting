CREATE PROCEDURE [dbo].[usp_Customer_Insert]
    @FirstName NVARCHAR(100),
    @LastName  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[Customer] ([FirstName], [LastName])
    VALUES (@FirstName, @LastName);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS [CustomerId];
END