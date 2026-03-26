namespace {{PROJECT_NAME}}.Application.Commands;

using MediatR;
using {{PROJECT_NAME}}.Application.DTOs;
using {{PROJECT_NAME}}.Domain.Entities;
using {{PROJECT_NAME}}.Domain.Interfaces;

/// <summary>
/// Handler for CreateUserCommand.
/// </summary>
public class CreateUserCommandHandler : IRequestHandler<CreateUserCommand, UserDto>
{
    private readonly IUserRepository _userRepository;

    public CreateUserCommandHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UserDto> Handle(CreateUserCommand request, CancellationToken ct)
    {
        // TODO: Hash password with proper algorithm (BCrypt/Argon2)
        var user = User.Create(request.Email, request.Name, request.Password);
        await _userRepository.AddAsync(user, ct);

        return new UserDto(
            user.Id, user.Email, user.Name,
            user.AvatarUrl, user.Bio,
            user.CreatedAt, user.UpdatedAt
        );
    }
}
