using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Infrastructure.Repositories;

public class OrderRepository : IOrderRepository
{
    private readonly IConnectionFactory _connectionFactory;

    public OrderRepository(IConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IEnumerable<Order>> GetAllAsync()
    {
        using var connection = _connectionFactory.Create();
        return await connection.QueryAsync<Order>(
            "dbo.usp_Order_GetAll",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<Order>> GetByCustomerIdAsync(int customerId)
    {
        using var connection = _connectionFactory.Create();
        return await connection.QueryAsync<Order>(
            "dbo.usp_Order_GetByCustomerId",
            new { CustomerId = customerId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Order?> GetByIdAsync(int orderId)
    {
        using var connection = _connectionFactory.Create();
        using var multi = await connection.QueryMultipleAsync(
            "dbo.usp_Order_GetById",
            new { OrderId = orderId },
            commandType: CommandType.StoredProcedure);

        var order = await multi.ReadSingleOrDefaultAsync<Order>();
        if (order is null)
        {
            return null;
        }

        order.LineItems = (await multi.ReadAsync<OrderLineItem>()).ToList();
        order.OrderTotal = order.LineItems.Sum(li => li.Quantity * li.UnitPrice);
        return order;
    }

    public async Task<int> InsertAsync(int customerId, int statusId, string? notes, IEnumerable<OrderLineItem> lineItems)
    {
        using var connection = (SqlConnection)_connectionFactory.Create();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            var orderId = await connection.ExecuteScalarAsync<int>(
                "dbo.usp_Order_Insert",
                new { CustomerId = customerId, StatusId = statusId, Notes = notes },
                transaction: transaction,
                commandType: CommandType.StoredProcedure);

            foreach (var lineItem in lineItems)
            {
                await connection.ExecuteAsync(
                    "dbo.usp_OrderLineItem_Insert",
                    new { OrderId = orderId, lineItem.ProductName, lineItem.Quantity, lineItem.UnitPrice },
                    transaction: transaction,
                    commandType: CommandType.StoredProcedure);
            }

            transaction.Commit();
            return orderId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateStatusAsync(int orderId, int statusId)
    {
        using var connection = _connectionFactory.Create();
        await connection.ExecuteAsync(
            "dbo.usp_Order_UpdateStatus",
            new { OrderId = orderId, StatusId = statusId },
            commandType: CommandType.StoredProcedure);
    }
}
