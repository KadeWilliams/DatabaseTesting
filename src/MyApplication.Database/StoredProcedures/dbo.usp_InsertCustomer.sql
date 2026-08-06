CREATE PROCEDURE [dbo].[usp_InsertCustomer]
    @FirstName NVARCHAR(100),
    @LastName  NVARCHAR(100),
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[Customer] ([FirstName], [LastName], [CreatedBy])
    VALUES (@FirstName, @LastName, @CreatedBy);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS [CustomerId];
END