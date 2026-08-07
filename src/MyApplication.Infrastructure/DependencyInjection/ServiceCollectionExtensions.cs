using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MyApplication.Core.Interfaces;
using MyApplication.Infrastructure.Database;
using MyApplication.Infrastructure.Repositories;

namespace MyApplication.Infrastructure.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<IConnectionFactory>(_ => new SqlConnectionFactory(configuration));
        services.AddScoped<IHealthCheckRepository, HealthCheckRepository>();
        services.AddScoped<ICustomerRepository, CustomerRepository>();

        return services;
    }
}
