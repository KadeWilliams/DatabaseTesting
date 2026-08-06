using System.Data;
using Dapper;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Infrastructure.Repositories;

public class StatusRepository : IStatusRepository
{
    private readonly IConnectionFactory _connectionFactory;

    public StatusRepository(IConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IEnumerable<Status>> GetAllAsync()
    {
        using var connection = _connectionFactory.Create();
        return await connection.QueryAsync<Status>(
            "dbo.usp_Status_GetAll",
            commandType: CommandType.StoredProcedure);
    }
}
