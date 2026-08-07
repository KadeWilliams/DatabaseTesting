CREATE PROCEDURE dbo.usp_Customer_Update (
    @CustomerId INT,
    @FirstName  NVARCHAR(50),
    @LastName   NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Customer
    SET FirstName = @FirstName,
        LastName  = @LastName
    WHERE CustomerId = @CustomerId;
END;
