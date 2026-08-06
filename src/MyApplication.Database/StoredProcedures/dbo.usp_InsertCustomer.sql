CREATE PROCEDURE [dbo].[usp_InsertCustomer]
    @FirstName NVARCHAR(50),
    @LastName  NVARCHAR(50),
    @CreatedBy NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[Customer] ([FirstName], [LastName], [CreatedBy])
    VALUES (@FirstName, @LastName, @CreatedBy);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS [CustomerId];
END