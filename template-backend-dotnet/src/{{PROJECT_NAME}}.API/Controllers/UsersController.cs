namespace {{PROJECT_NAME}}.API.Controllers;

using MediatR;
using Microsoft.AspNetCore.Mvc;
using {{PROJECT_NAME}}.Application.Commands;
using {{PROJECT_NAME}}.Application.DTOs;
using {{PROJECT_NAME}}.Application.Queries;

/// <summary>
/// User management endpoints.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IMediator _mediator;

    public UsersController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Get user by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var user = await _mediator.Send(new GetUserQuery(id), ct);
        return user is null ? NotFound() : Ok(user);
    }

    /// <summary>
    /// Create a new user.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateUserCommand command, CancellationToken ct)
    {
        var user = await _mediator.Send(command, ct);
        return CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
    }
}
