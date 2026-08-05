using MyApplication.Core.Models;

namespace MyApplication.Core.Interfaces;

public interface ICustomerRepository
{
    Task<IEnumerable<Customer>> GetAllAsync(string? searchLastName = null);
    Task<Customer?> GetByIdAsync(int customerId);
    Task<int> InsertAsync(Customer customer);
    Task UpdateAsync(Customer customer);
    Task DeleteAsync(int customerId);
}
