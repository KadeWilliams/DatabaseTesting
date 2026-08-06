using Microsoft.Extensions.DependencyInjection;
using MyApplication.Core.Interfaces;
using MyApplication.Infrastructure.Repositories;

namespace MyApplication.Infrastructure;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        services.AddSingleton<IConnectionFactory, SqlConnectionFactory>();
        services.AddScoped<ICustomerRepository, CustomerRepository>();
        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<IStatusRepository, StatusRepository>();
        return services;
    }
}
