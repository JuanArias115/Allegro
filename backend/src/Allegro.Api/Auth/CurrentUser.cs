using System.Security.Claims;
using Allegro.Application.Abstractions;

namespace Allegro.Api.Auth;

/// <summary>
/// Lee la identidad del usuario autenticado desde el <c>HttpContext</c>. En modo
/// Firebase el UID viene en <c>user_id</c>/<c>sub</c>; en modo desarrollo lo
/// provee <see cref="LocalDevAuthHandler"/>.
/// </summary>
public sealed class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _accessor;

    public CurrentUser(IHttpContextAccessor accessor) => _accessor = accessor;

    private ClaimsPrincipal? User => _accessor.HttpContext?.User;

    public bool IsAuthenticated => User?.Identity?.IsAuthenticated == true;

    public string? Uid =>
        User?.FindFirst("user_id")?.Value
        ?? User?.FindFirst("sub")?.Value
        ?? User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    public string? Name =>
        User?.FindFirst("name")?.Value
        ?? User?.FindFirst(ClaimTypes.Name)?.Value;

    public string? Role => User?.FindFirst(AppClaims.Role)?.Value;
}
