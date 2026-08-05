CREATE PROCEDURE [dbo].[usp_Customer_GetAll]
    @SearchLastName NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [CustomerId], [FirstName], [LastName], [Email], [CreatedAtUtc]
    FROM [dbo].[Customer]
    WHERE @SearchLastName IS NULL OR [LastName] LIKE '%' + @SearchLastName + '%'
    ORDER BY [LastName], [FirstName];
END
