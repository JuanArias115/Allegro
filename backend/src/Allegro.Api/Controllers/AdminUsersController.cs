using Allegro.Api.Auth;
using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Allegro.Api.Controllers;

/// <summary>
/// Gestión de usuarios de Firebase. Solo administradores. Las operaciones
/// sensibles están limitadas por tasa. NUNCA expone objetos del SDK ni contraseñas.
/// </summary>
[ApiController]
[Authorize(Policy = Policies.Admin)]
[EnableRateLimiting("admin-sensitive")]
[Route("api/admin/users")]
public class AdminUsersController : ControllerBase
{
    private readonly IAdminUserService _service;

    public AdminUsersController(IAdminUserService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<UserPageDto>> List(
        [FromQuery] string? query, [FromQuery] string? pageToken, [FromQuery] int pageSize = 25, CancellationToken ct = default)
        => Ok(await _service.ListAsync(query, pageToken, pageSize, ct));

    [HttpGet("{uid}")]
    public async Task<ActionResult<AdminUserDto>> Get(string uid, CancellationToken ct)
    {
        var user = await _service.GetAsync(uid, ct);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost]
    public async Task<ActionResult<CreateUserResultDto>> Create(CreateUserDto dto, CancellationToken ct)
        => Ok(await _service.CreateAsync(dto, ct));

    [HttpPatch("{uid}")]
    public async Task<ActionResult<AdminUserDto>> Update(string uid, UpdateUserDto dto, CancellationToken ct)
        => Ok(await _service.UpdateAsync(uid, dto, ct));

    [HttpPost("{uid}/activation-link")]
    public async Task<ActionResult<ActivationLinkDto>> ActivationLink(string uid, CancellationToken ct)
        => Ok(await _service.GenerateActivationLinkAsync(uid, ct));

    [HttpPost("{uid}/revoke-sessions")]
    public async Task<IActionResult> RevokeSessions(string uid, CancellationToken ct)
    {
        await _service.RevokeSessionsAsync(uid, ct);
        return NoContent();
    }

    [HttpPatch("{uid}/status")]
    public async Task<ActionResult<AdminUserDto>> ChangeStatus(string uid, ChangeUserStatusDto dto, CancellationToken ct)
        => Ok(await _service.SetStatusAsync(uid, dto.Disabled, ct));
}
