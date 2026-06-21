using Allegro.Application.Dtos;

namespace Allegro.Application.Abstractions;

/// <summary>
/// Abstracción sobre Firebase Admin SDK para gestión de usuarios. Evita acoplar los
/// endpoints/servicios al SDK y permite mockear en pruebas (nunca se conecta al
/// proyecto Firebase real en tests). Las implementaciones devuelven DTOs propios y
/// NUNCA exponen objetos del SDK ni credenciales.
/// </summary>
public interface IFirebaseUserManagementService
{
    /// <summary>Lista usuarios paginados. <paramref name="query"/> filtra por correo o nombre (case-insensitive).</summary>
    Task<UserPageDto> ListAsync(string? query, string? pageToken, int pageSize, CancellationToken ct = default);

    Task<AdminUserDto?> GetByUidAsync(string uid, CancellationToken ct = default);

    Task<AdminUserDto?> GetByEmailAsync(string email, CancellationToken ct = default);

    /// <summary>Crea el usuario (sin contraseña visible) y asigna claims app_access + role.</summary>
    Task<AdminUserDto> CreateAsync(string name, string email, string role, CancellationToken ct = default);

    Task<AdminUserDto> UpdateNameAsync(string uid, string name, CancellationToken ct = default);

    /// <summary>Asigna claims app_access=true + role. Idempotente.</summary>
    Task<AdminUserDto> SetRoleAsync(string uid, string role, CancellationToken ct = default);

    Task<AdminUserDto> SetDisabledAsync(string uid, bool disabled, CancellationToken ct = default);

    Task RevokeSessionsAsync(string uid, CancellationToken ct = default);

    /// <summary>Genera un enlace para establecer/restablecer contraseña.</summary>
    Task<string> GeneratePasswordResetLinkAsync(string email, CancellationToken ct = default);

    /// <summary>Cuenta administradores activos (rol admin y no bloqueados). Para proteger al último admin.</summary>
    Task<int> CountActiveAdminsAsync(CancellationToken ct = default);
}
