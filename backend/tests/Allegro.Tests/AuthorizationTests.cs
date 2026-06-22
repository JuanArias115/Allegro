using System.Net;
using System.Net.Http.Headers;
using Microsoft.AspNetCore.Mvc.Testing;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

/// <summary>
/// Pruebas de las políticas de autorización a nivel HTTP. Usan AUTH_MODE=local
/// (sin Firebase) y LOCAL_DEV_ROLE para simular admin/operator. No tocan la base
/// (APPLY_MIGRATIONS=false): el 401/403 se resuelve antes de llegar al controlador.
/// </summary>
public class AuthorizationTests
{
    private const string DevToken = "allegro-dev-token";

    private static WebApplicationFactory<Program> Factory(string role) =>
        new WebApplicationFactory<Program>().WithWebHostBuilder(b =>
        {
            b.UseSetting("environment", "Development");
            b.UseSetting("AUTH_MODE", "local");
            b.UseSetting("APPLY_MIGRATIONS", "false");
            b.UseSetting("SEED_DEMO_DATA", "false");
            b.UseSetting("LOCAL_DEV_ROLE", role);
            b.UseSetting("LOCAL_DEV_TOKEN", DevToken);
            b.UseSetting("ConnectionStrings:Default", "Host=localhost;Database=unused;Username=u;Password=p");
        });

    private static HttpClient Authed(WebApplicationFactory<Program> f)
    {
        var client = f.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", DevToken);
        return client;
    }

    [Fact]
    public async Task Admin_endpoint_without_token_is_401()
    {
        using var f = Factory("admin");
        var client = f.CreateClient();

        var res = await client.GetAsync("/api/admin/users");

        res.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Admin_endpoint_with_operator_is_403()
    {
        using var f = Factory("operator");
        var client = Authed(f);

        var res = await client.GetAsync("/api/admin/users");

        res.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Admin_endpoint_with_admin_is_allowed()
    {
        using var f = Factory("admin");
        var client = Authed(f);

        var res = await client.GetAsync("/api/admin/users");

        // 200: el stub de Firebase devuelve lista vacía (sin tocar la base).
        res.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Reports_require_admin_operator_gets_403()
    {
        using var f = Factory("operator");
        var client = Authed(f);

        var res = await client.GetAsync("/api/admin/reports/summary?from=2026-07-01&to=2026-08-01");

        res.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }
}
