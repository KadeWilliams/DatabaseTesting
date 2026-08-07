using MyApplication.Core.Models;

namespace MyApplication.Core.Interfaces;

public interface ICustomerRepository
{
    Customer? GetCustomerById(int customerId);
    void UpdateCustomer(int customerId, string firstName, string lastName);
}
