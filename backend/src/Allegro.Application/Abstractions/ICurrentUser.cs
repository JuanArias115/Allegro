namespace Allegro.Application.Abstractions;

/// <summary>
/// Identidad del usuario autenticado en la petición actual. La implementación
/// concreta (lectura de claims del <c>HttpContext</c>) vive en la capa Api.
/// </summary>
public interface ICurrentUser
{
    /// <summary>Firebase UID (o id del usuario de desarrollo). Null si no autenticado.</summary>
    string? Uid { get; }

    /// <summary>Nombre visible si está disponible.</summary>
    string? Name { get; }

    /// <summary>Rol declarado en los claims (<c>admin</c> | <c>operator</c>) o null.</summary>
    string? Role { get; }

    bool IsAuthenticated { get; }
}
