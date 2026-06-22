using Allegro.Application.Abstractions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;

namespace Allegro.Api.Auth;

public static class AuthSetup
{
    /// <summary>
    /// Configura la autenticación según AUTH_MODE:
    ///   firebase -> valida tokens de Firebase Authentication contra Google.
    ///   local    -> modo desarrollo con token estático (nunca en producción).
    /// </summary>
    public static IServiceCollection AddAllegroAuth(this IServiceCollection services, IConfiguration config, IWebHostEnvironment env)
    {
        var mode = (config["AUTH_MODE"] ?? "local").Trim().ToLowerInvariant();

        if (mode == "firebase")
        {
            var projectId = config["FIREBASE_PROJECT_ID"];
            if (string.IsNullOrWhiteSpace(projectId))
                throw new InvalidOperationException("AUTH_MODE=firebase requiere FIREBASE_PROJECT_ID.");

            var authority = $"https://securetoken.google.com/{projectId}";
            services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.Authority = authority;
                    // Conservamos los nombres de claim originales del token de Firebase
                    // (user_id, sub, role, app_access) sin el mapeo heredado de .NET.
                    options.MapInboundClaims = false;
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidIssuer = authority,
                        ValidateAudience = true,
                        ValidAudience = projectId,
                        ValidateLifetime = true
                    };
                });
        }
        else
        {
            if (env.IsProduction())
                throw new InvalidOperationException(
                    "AUTH_MODE=local no está permitido en producción. Configura AUTH_MODE=firebase.");

            services.AddAuthentication(LocalDevAuthHandler.SchemeName)
                .AddScheme<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions, LocalDevAuthHandler>(
                    LocalDevAuthHandler.SchemeName, _ => { });
        }

        // Identidad del usuario para la capa de aplicación (auditoría, etc.).
        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUser, CurrentUser>();

        // Mientras la migración de claims está en curso, los endpoints normales
        // solo exigen el claim app_access si se activa explícitamente. Los
        // endpoints administrativos SIEMPRE exigen rol admin.
        var requireAppAccess = ReadBool(config["Authorization:RequireAppAccessClaim"], defaultValue: false);

        services.AddSingleton<IAuthorizationHandler, AppAccessHandler>();
        services.AddAuthorization(options =>
        {
            var appAccess = new AuthorizationPolicyBuilder()
                .RequireAuthenticatedUser()
                .AddRequirements(new AppAccessRequirement(requireAppAccess))
                .Build();

            // [Authorize] sin política usa esta por defecto (comportamiento actual + app_access opcional).
            options.DefaultPolicy = appAccess;
            options.AddPolicy(Policies.AppAccess, appAccess);

            options.AddPolicy(Policies.Admin, p => p
                .RequireAuthenticatedUser()
                .RequireClaim(AppClaims.Role, Roles.Admin));

            options.AddPolicy(Policies.Operator, p => p
                .RequireAuthenticatedUser()
                .RequireAssertion(ctx =>
                    ctx.User.HasClaim(AppClaims.Role, Roles.Admin) ||
                    ctx.User.HasClaim(AppClaims.Role, Roles.Operator)));
        });

        return services;
    }

    private static bool ReadBool(string? value, bool defaultValue) =>
        string.IsNullOrWhiteSpace(value) ? defaultValue : value.Trim().ToLowerInvariant() is "true" or "1" or "yes";
}
