MERGE INTO [dbo].[Status] AS [Target]
USING (VALUES
    (N'Pending',    1),
    (N'Processing', 2),
    (N'Shipped',    3),
    (N'Delivered',  4),
    (N'Cancelled',  5)
) AS [Source] ([Name], [SortOrder])
ON [Target].[Name] = [Source].[Name]
WHEN MATCHED THEN
    UPDATE SET [Target].[SortOrder] = [Source].[SortOrder]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([Name], [SortOrder])
    VALUES ([Source].[Name], [Source].[SortOrder]);
