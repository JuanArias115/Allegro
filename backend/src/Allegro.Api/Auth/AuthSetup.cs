using Microsoft.AspNetCore.Authentication.JwtBearer;
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

        services.AddAuthorization();
        return services;
    }
}
