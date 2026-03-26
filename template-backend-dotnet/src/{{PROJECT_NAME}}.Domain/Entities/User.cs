namespace {{PROJECT_NAME}}.Domain.Entities;

/// <summary>
/// User domain entity.
/// </summary>
public class User : BaseEntity
{
    public string Email { get; private set; } = string.Empty;
    public string Name { get; private set; } = string.Empty;
    public string PasswordHash { get; private set; } = string.Empty;
    public string? AvatarUrl { get; private set; }
    public string? Bio { get; private set; }

    private User() { }

    public static User Create(string email, string name, string passwordHash)
    {
        return new User
        {
            Email = email,
            Name = name,
            PasswordHash = passwordHash,
        };
    }

    public void UpdateProfile(string? name = null, string? avatarUrl = null, string? bio = null)
    {
        if (name is not null) Name = name;
        if (avatarUrl is not null) AvatarUrl = avatarUrl;
        if (bio is not null) Bio = bio;
        UpdatedAt = DateTime.UtcNow;
    }
}
