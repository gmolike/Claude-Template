namespace {{PROJECT_NAME}}.Application.DTOs;

/// <summary>
/// Authentication response with tokens and user info.
/// </summary>
public record AuthResponseDto(
    string AccessToken,
    string RefreshToken,
    int ExpiresIn,
    UserDto User
);
