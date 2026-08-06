-- Demo/reference data so `docker compose up` produces something worth looking
-- at immediately, with no manual setup. Guarded so it only seeds once.
IF NOT EXISTS (SELECT 1 FROM [dbo].[Customer])
BEGIN
    DECLARE @Customers TABLE ([CustomerId] INT, [LastName] NVARCHAR(100));

    INSERT INTO [dbo].[Customer] ([FirstName], [LastName], [Email])
    OUTPUT INSERTED.[CustomerId], INSERTED.[LastName] INTO @Customers
    VALUES
        (N'Ada',     N'Lovelace', N'ada.lovelace@example.com'),
        (N'Grace',   N'Hopper',   N'grace.hopper@example.com'),
        (N'Alan',    N'Turing',   N'alan.turing@example.com');

    DECLARE @PendingStatusId INT = (SELECT [StatusId] FROM [dbo].[Status] WHERE [Name] = N'Pending');
    DECLARE @ShippedStatusId INT = (SELECT [StatusId] FROM [dbo].[Status] WHERE [Name] = N'Shipped');

    DECLARE @AdaId INT = (SELECT [CustomerId] FROM @Customers WHERE [LastName] = N'Lovelace');
    DECLARE @GraceId INT = (SELECT [CustomerId] FROM @Customers WHERE [LastName] = N'Hopper');

    DECLARE @Orders TABLE ([OrderId] INT, [Seq] INT);

    INSERT INTO [dbo].[Order] ([CustomerId], [StatusId], [Notes])
    OUTPUT INSERTED.[OrderId], 1 INTO @Orders
    VALUES (@AdaId, @ShippedStatusId, N'First analytical engine punch cards');

    INSERT INTO [dbo].[Order] ([CustomerId], [StatusId], [Notes])
    OUTPUT INSERTED.[OrderId], 2 INTO @Orders
    VALUES (@GraceId, @PendingStatusId, N'COBOL compiler manuals');

    INSERT INTO [dbo].[OrderLineItem] ([OrderId], [ProductName], [Quantity], [UnitPrice])
    SELECT [OrderId], N'Punch Card Deck', 3, 12.50 FROM @Orders WHERE [Seq] = 1
    UNION ALL
    SELECT [OrderId], N'Difference Engine Manual', 1, 45.00 FROM @Orders WHERE [Seq] = 1
    UNION ALL
    SELECT [OrderId], N'COBOL Reference Manual', 2, 30.00 FROM @Orders WHERE [Seq] = 2;
END
