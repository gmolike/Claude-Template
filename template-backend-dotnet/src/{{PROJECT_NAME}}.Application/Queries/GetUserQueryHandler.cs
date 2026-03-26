namespace {{PROJECT_NAME}}.Application.Queries;

using MediatR;
using {{PROJECT_NAME}}.Application.DTOs;
using {{PROJECT_NAME}}.Domain.Interfaces;

/// <summary>
/// Handler for GetUserQuery.
/// </summary>
public class GetUserQueryHandler : IRequestHandler<GetUserQuery, UserDto?>
{
    private readonly IUserRepository _userRepository;

    public GetUserQueryHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UserDto?> Handle(GetUserQuery request, CancellationToken ct)
    {
        var user = await _userRepository.GetByIdAsync(request.Id, ct);
        if (user is null) return null;

        return new UserDto(
            user.Id, user.Email, user.Name,
            user.AvatarUrl, user.Bio,
            user.CreatedAt, user.UpdatedAt
        );
    }
}
