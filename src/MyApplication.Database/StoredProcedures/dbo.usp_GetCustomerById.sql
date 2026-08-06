CREATE PROCEDURE dbo.usp_GetCustomerById (
    @CustomerId INT
)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * 
    FROM dbo.Customer
    WHERE CustomerId = @CustomerId;
END;
