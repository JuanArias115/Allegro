using Allegro.Application.Abstractions;
using Allegro.Domain;

namespace Allegro.Application.Services;

public interface IAuditLogService
{
    /// <summary>
    /// Registra una acción administrativa sensible. El actor se toma del usuario
    /// autenticado actual. El detalle debe ser mínimo y no sensible (nunca tokens,
    /// enlaces de activación ni credenciales).
    /// </summary>
    Task LogAsync(string action, string? targetId, string? detail, CancellationToken ct = default);
}

public class AuditLogService : IAuditLogService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IClock _clock;

    public AuditLogService(IAppDbContext db, ICurrentUser currentUser, IClock clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    public async Task LogAsync(string action, string? targetId, string? detail, CancellationToken ct = default)
    {
        var entry = new AuditLog
        {
            ActorUid = _currentUser.Uid ?? "unknown",
            Action = action,
            TargetId = targetId,
            AtUtc = _clock.UtcNow,
            Detail = Trim(detail),
        };
        _db.AuditLogs.Add(entry);
        await _db.SaveChangesAsync(ct);
    }

    // Cota defensiva: el detalle es informativo, no debe crecer sin límite.
    private static string? Trim(string? detail) =>
        string.IsNullOrWhiteSpace(detail) ? null
        : detail.Length <= 500 ? detail
        : detail[..500];
}
