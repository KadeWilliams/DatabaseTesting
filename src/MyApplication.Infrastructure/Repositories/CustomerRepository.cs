using System.Data;
using Dapper;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;
using MyApplication.Infrastructure.Database;

namespace MyApplication.Infrastructure.Repositories;

public sealed class CustomerRepository : ICustomerRepository
{
    private readonly IConnectionFactory _connectionFactory;

    public CustomerRepository(IConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public Customer? GetCustomerById(int customerId)
    {
        using var connection = _connectionFactory.Create();
        connection.Open();
        return connection.QuerySingleOrDefault<Customer>(
            "dbo.usp_GetCustomerById",
            new { CustomerId = customerId },
            commandType: CommandType.StoredProcedure);
    }

    public void UpdateCustomer(int customerId, string firstName, string lastName)
    {
        using var connection = _connectionFactory.Create();
        connection.Open();
        connection.Execute(
            "dbo.usp_Customer_Update",
            new { CustomerId = customerId, FirstName = firstName, LastName = lastName },
            commandType: CommandType.StoredProcedure);
    }
}
