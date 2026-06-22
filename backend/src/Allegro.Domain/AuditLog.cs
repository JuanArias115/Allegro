namespace Allegro.Domain;

/// <summary>
/// Registro de una acción administrativa sensible (creación de usuario, cambio de
/// rol, bloqueo/reactivación, revocación de sesiones, cambio de configuración).
/// Solo guarda información mínima y NO sensible: nunca tokens, enlaces de
/// activación, contraseñas ni credenciales.
/// </summary>
public class AuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>Firebase UID de quien ejecutó la acción.</summary>
    public string ActorUid { get; set; } = string.Empty;

    /// <summary>Identificador estable de la acción (ver <see cref="Allegro.Domain.AuditActions"/>).</summary>
    public string Action { get; set; } = string.Empty;

    /// <summary>Identificador del objeto afectado (p. ej. UID del usuario destino).</summary>
    public string? TargetId { get; set; }

    /// <summary>Marca temporal en UTC.</summary>
    public DateTime AtUtc { get; set; }

    /// <summary>Detalle mínimo no sensible (p. ej. "role: operator -> admin").</summary>
    public string? Detail { get; set; }
}

/// <summary>Nombres estables de acciones auditables.</summary>
public static class AuditActions
{
    public const string UserCreated = "user.created";
    public const string UserRoleChanged = "user.role_changed";
    public const string UserNameChanged = "user.name_changed";
    public const string UserStatusChanged = "user.status_changed";
    public const string UserSessionsRevoked = "user.sessions_revoked";
    public const string UserActivationLink = "user.activation_link_generated";
    public const string ConfigChanged = "config.changed";
}
