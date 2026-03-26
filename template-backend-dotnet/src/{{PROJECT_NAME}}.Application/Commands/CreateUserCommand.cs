namespace {{PROJECT_NAME}}.Application.Commands;

using MediatR;
using {{PROJECT_NAME}}.Application.DTOs;

/// <summary>
/// Command to create a new user (registration).
/// </summary>
public record CreateUserCommand(string Email, string Name, string Password) : IRequest<UserDto>;
