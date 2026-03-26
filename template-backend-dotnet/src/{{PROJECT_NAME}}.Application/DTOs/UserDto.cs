namespace {{PROJECT_NAME}}.Application.DTOs;

/// <summary>
/// User data transfer object.
/// </summary>
public record UserDto(
    Guid Id,
    string Email,
    string Name,
    string? AvatarUrl,
    string? Bio,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);
