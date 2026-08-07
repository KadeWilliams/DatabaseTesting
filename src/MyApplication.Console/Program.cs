using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace MyApplication.Console;

public interface IConnectionFactory
{
    IDbConnection Create();
}

public sealed class SqlConnectionFactory : IConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");
    }

    public IDbConnection Create() => new SqlConnection(_connectionString);
}

public static class Program
{
    public static void Main(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
            .AddEnvironmentVariables()
            .Build();

        IConnectionFactory connectionFactory = new SqlConnectionFactory(configuration);

        using var connection = connectionFactory.Create();
        connection.Open();

        var result = connection.QuerySingle<int>("SELECT 1");
        System.Console.WriteLine($"Database connection successful. Test query returned: {result}");
    }
}