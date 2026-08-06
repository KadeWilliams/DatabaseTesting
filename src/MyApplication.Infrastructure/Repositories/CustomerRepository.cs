using System.Data;
using Dapper;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Infrastructure.Repositories;

public class CustomerRepository : ICustomerRepository
{
    private readonly IConnectionFactory _connectionFactory;

    public CustomerRepository(IConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IEnumerable<Customer>> GetAllAsync(string? searchLastName = null)
    {
        using var connection = _connectionFactory.Create();
        return await connection.QueryAsync<Customer>(
            "dbo.usp_Customer_GetAll",
            new { SearchLastName = searchLastName },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Customer?> GetByIdAsync(int customerId)
    {
        using var connection = _connectionFactory.Create();
        return await connection.QuerySingleOrDefaultAsync<Customer>(
            "dbo.usp_Customer_GetById",
            new { CustomerId = customerId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> InsertAsync(Customer customer)
    {
        using var connection = _connectionFactory.Create();
        return await connection.ExecuteScalarAsync<int>(
            "dbo.usp_Customer_Insert",
            new { customer.FirstName, customer.LastName, customer.Email },
            commandType: CommandType.StoredProcedure);
    }

    public async Task UpdateAsync(Customer customer)
    {
        using var connection = _connectionFactory.Create();
        await connection.ExecuteAsync(
            "dbo.usp_Customer_Update",
            new { customer.CustomerId, customer.FirstName, customer.LastName, customer.Email },
            commandType: CommandType.StoredProcedure);
    }

    public async Task DeleteAsync(int customerId)
    {
        using var connection = _connectionFactory.Create();
        await connection.ExecuteAsync(
            "dbo.usp_Customer_Delete",
            new { CustomerId = customerId },
            commandType: CommandType.StoredProcedure);
    }
}
