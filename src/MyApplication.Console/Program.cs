using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MyApplication.Infrastructure.DependencyInjection;
using MyApplication.Infrastructure.Repositories;

namespace MyApplication.Console;

public static class Program
{
    public static void Main(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
            .AddEnvironmentVariables()
            .Build();

        var services = new ServiceCollection();
        services.AddInfrastructure(configuration);

        using var provider = services.BuildServiceProvider();
        using var scope = provider.CreateScope();

        var healthCheckRepository = scope.ServiceProvider.GetRequiredService<IHealthCheckRepository>();
        var result = healthCheckRepository.CheckConnection();
        System.Console.WriteLine($"Database connection successful. Test query returned: {result}");
        
        var customerRepository = scope.ServiceProvider.GetRequiredService<ICustomerRepository>();
        customerRepository.UpdateCustomer(customerId: 1, FirstName: "Kade", LastName: "Williams");
        
        var customer = customerRepository.GetCustomerById(1);
        System.Console.WriteLine($"Updated CustomerId: {customer}");
    }
}