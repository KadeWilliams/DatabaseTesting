using Dapper;
using MyApplication.Infrastructure.Database;

namespace MyApplication.Infrastructure.Repositories;

public sealed class CustomerRepository : ICustomerRepository
{
    private readonly IConnectionFactory _connectionFactory;

    public CustomerRepository(IConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public void UpdateCustomer(int customerId, string FirstName, string LastName)
    {
        using var connection = _connectionFactory.Create();
        connection.Open();
        connection.Execute("UPDATE dbo.Customer SET FirstName = @FirstName, LastName = @LastName WHERE CustomerId = @CustomerId",
            new { CustomerId = customerId, FirstName = FirstName, LastName = LastName });
    }
    
    public dynamic GetCustomerById(int customerId)
    {
        using var connection = _connectionFactory.Create();
        connection.Open();
        return connection.QueryFirstOrDefault<dynamic>("SELECT * FROM dbo.Customer WHERE CustomerId = @CustomerId",
            new { CustomerId = customerId});
    }
}