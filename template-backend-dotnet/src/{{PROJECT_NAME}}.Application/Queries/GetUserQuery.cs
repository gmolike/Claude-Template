namespace {{PROJECT_NAME}}.Application.Queries;

using MediatR;
using {{PROJECT_NAME}}.Application.DTOs;

/// <summary>
/// Query to get a user by ID.
/// </summary>
public record GetUserQuery(Guid Id) : IRequest<UserDto?>;
