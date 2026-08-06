CREATE PROCEDURE [dbo].[usp_Status_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [StatusId], [Name], [SortOrder]
    FROM [dbo].[Status]
    ORDER BY [SortOrder];
END
