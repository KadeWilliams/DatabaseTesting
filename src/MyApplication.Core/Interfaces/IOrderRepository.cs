using MyApplication.Core.Models;

namespace MyApplication.Core.Interfaces;

public interface IOrderRepository
{
    Task<IEnumerable<Order>> GetAllAsync();
    Task<IEnumerable<Order>> GetByCustomerIdAsync(int customerId);
    Task<Order?> GetByIdAsync(int orderId);
    Task<int> InsertAsync(int customerId, int statusId, string? notes, IEnumerable<OrderLineItem> lineItems);
    Task UpdateStatusAsync(int orderId, int statusId);
}
