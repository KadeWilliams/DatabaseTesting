CREATE TABLE dbo.CustomerHistory (
     CustomerId INT NOT NULL,
     FirstName NVARCHAR(50) NOT NULL,
     LastName NVARCHAR(50) NOT NULL,
     CreatedBy NVARCHAR(50) NOT NULL,
     UpdatedBy NVARCHAR(50) NULL,
     ValidFrom DATETIME2(0) NOT NULL,
     ValidTo DATETIME2(0) NOT NULL
)