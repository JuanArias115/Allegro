using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace Allegro.Api.Auth;

/// <summary>
/// Requisito de "acceso a la aplicación". Cuando
/// <c>Authorization:RequireAppAccessClaim</c> es <c>true</c>, exige el claim
/// <c>app_access=true</c>; mientras sea <c>false</c> basta con estar autenticado
/// (compatibilidad con los usuarios actuales de Flutter que aún no tienen claims).
/// </summary>
public sealed class AppAccessRequirement : IAuthorizationRequirement
{
    public bool RequireClaim { get; }

    public AppAccessRequirement(bool requireClaim) => RequireClaim = requireClaim;
}

public sealed class AppAccessHandler : AuthorizationHandler<AppAccessRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context, AppAccessRequirement requirement)
    {
        if (context.User?.Identity?.IsAuthenticated != true)
            return Task.CompletedTask; // no autenticado -> falla

        if (!requirement.RequireClaim || HasAppAccess(context.User))
            context.Succeed(requirement);

        return Task.CompletedTask;
    }

    internal static bool HasAppAccess(ClaimsPrincipal user)
    {
        var claim = user.FindFirst(AppClaims.AppAccess)?.Value;
        return string.Equals(claim, "true", StringComparison.OrdinalIgnoreCase);
    }
}
