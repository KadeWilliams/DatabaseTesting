using Dapper;
using MyApplication.Core.Interfaces;
using MyApplication.Infrastructure.Database;

namespace MyApplication.Infrastructure.Repositories;

public sealed class HealthCheckRepository : IHealthCheckRepository
{
    private readonly IConnectionFactory _connectionFactory;

    public HealthCheckRepository(IConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public int CheckConnection()
    {
        using var connection = _connectionFactory.Create();
        connection.Open();
        return connection.QuerySingle<int>("SELECT 1");
    }
}
