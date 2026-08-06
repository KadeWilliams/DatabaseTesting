-- FOR SYSTEM_TIME ALL returns every version of the row that ever existed
-- (current + all archived versions from CustomerHistory) in one query,
-- entirely maintained by the engine — nothing in the app wrote these rows.
CREATE PROCEDURE [dbo].[usp_Customer_GetHistory]
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [CustomerId], [FirstName], [LastName], [Email], [CreatedAtUtc], [ValidFrom], [ValidTo]
    FROM [dbo].[Customer] FOR SYSTEM_TIME ALL
    WHERE [CustomerId] = @CustomerId
    ORDER BY [ValidFrom] DESC;
END
