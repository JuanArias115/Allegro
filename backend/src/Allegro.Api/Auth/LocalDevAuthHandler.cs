using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace Allegro.Api.Auth;

/// <summary>
/// Modo de desarrollo: acepta un token estático configurado por variable de entorno.
/// NUNCA debe usarse en producción. Se activa solo cuando AUTH_MODE=local.
/// </summary>
public class LocalDevAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "LocalDev";
    private readonly string _expectedToken;

    public LocalDevAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IConfiguration config)
        : base(options, logger, encoder)
    {
        _expectedToken = config["LOCAL_DEV_TOKEN"]
            ?? Environment.GetEnvironmentVariable("LOCAL_DEV_TOKEN")
            ?? "allegro-dev-token";
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var header = Request.Headers.Authorization.ToString();
        if (string.IsNullOrWhiteSpace(header) || !header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            return Task.FromResult(AuthenticateResult.Fail("Falta el token de autorización."));

        var token = header["Bearer ".Length..].Trim();
        if (token != _expectedToken)
            return Task.FromResult(AuthenticateResult.Fail("Token de desarrollo inválido."));

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "local-dev-user"),
            new Claim(ClaimTypes.Name, "Operador (dev)")
        };
        var identity = new ClaimsIdentity(claims, SchemeName);
        var ticket = new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
