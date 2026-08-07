using System.Data;

namespace MyApplication.Infrastructure.Database;

public interface IConnectionFactory
{
    IDbConnection Create();
}
