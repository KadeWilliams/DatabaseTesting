using MyApplication.Core.Models;

namespace MyApplication.Core.Interfaces;

public interface IStatusRepository
{
    Task<IEnumerable<Status>> GetAllAsync();
}
