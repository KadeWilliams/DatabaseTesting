CREATE PROCEDURE dbo.usp_GetCustomerById (
    @CustomerId INT
)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT CustomerId, FirstName, LastName
    FROM dbo.Customer
    WHERE CustomerId = @CustomerId;
END;
