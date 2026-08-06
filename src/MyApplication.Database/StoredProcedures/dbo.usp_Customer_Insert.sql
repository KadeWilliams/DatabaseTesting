CREATE PROCEDURE [dbo].[usp_Customer_Insert]
    @FirstName NVARCHAR(100),
    @LastName  NVARCHAR(100),
    @Email     NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[Customer] ([FirstName], [LastName], [Email])
    VALUES (@FirstName, @LastName, @Email);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS [CustomerId];
END
