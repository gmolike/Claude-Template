namespace {{PROJECT_NAME}}.Domain.Interfaces;

using {{PROJECT_NAME}}.Domain.Entities;

/// <summary>
/// Repository interface for User entity.
/// </summary>
public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task<User> AddAsync(User user, CancellationToken ct = default);
    Task UpdateAsync(User user, CancellationToken ct = default);
}
