namespace MyApplication.Infrastructure.Repositories;

public interface ICustomerRepository
{
    void UpdateCustomer(int customerId, string FirstName, string LastName);
    dynamic GetCustomerById(int customerId);
}