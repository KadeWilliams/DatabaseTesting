CREATE PROCEDURE [dbo].[usp_Customer_Update]
    @CustomerId INT,
    @FirstName  NVARCHAR(100),
    @LastName   NVARCHAR(100),
    @Email      NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [dbo].[Customer]
    SET [FirstName] = @FirstName,
        [LastName]  = @LastName,
        [Email]     = @Email
    WHERE [CustomerId] = @CustomerId;
END
