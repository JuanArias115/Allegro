using Allegro.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Allegro.Api.HealthChecks;

/// <summary>Comprueba que la base de datos esté accesible (readiness).</summary>
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly AllegroDbContext _db;

    public DatabaseHealthCheck(AllegroDbContext db) => _db = db;

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken ct = default)
    {
        try
        {
            return await _db.Database.CanConnectAsync(ct)
                ? HealthCheckResult.Healthy("Base de datos accesible.")
                : HealthCheckResult.Unhealthy("No se pudo conectar a la base de datos.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Error al conectar a la base de datos.", ex);
        }
    }
}
