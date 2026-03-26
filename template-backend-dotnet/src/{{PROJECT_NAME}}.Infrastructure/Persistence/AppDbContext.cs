namespace {{PROJECT_NAME}}.Infrastructure.Persistence;

using Microsoft.EntityFrameworkCore;
using {{PROJECT_NAME}}.Domain.Entities;

/// <summary>
/// Application database context.
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
