using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;

namespace Allegro.Application.Services;

/// <summary>
/// Orquesta la gestión de usuarios: aplica reglas de negocio (protección del último
/// administrador, validación de roles), audita las acciones sensibles y delega en
/// <see cref="IFirebaseUserManagementService"/>. NO conoce el SDK de Firebase.
/// </summary>
public interface IAdminUserService
{
    Task<UserPageDto> ListAsync(string? query, string? pageToken, int pageSize, CancellationToken ct = default);
    Task<AdminUserDto?> GetAsync(string uid, CancellationToken ct = default);
    Task<CreateUserResultDto> CreateAsync(CreateUserDto dto, CancellationToken ct = default);
    Task<AdminUserDto> UpdateAsync(string uid, UpdateUserDto dto, CancellationToken ct = default);
    Task<AdminUserDto> SetStatusAsync(string uid, bool disabled, CancellationToken ct = default);
    Task RevokeSessionsAsync(string uid, CancellationToken ct = default);
    Task<ActivationLinkDto> GenerateActivationLinkAsync(string uid, CancellationToken ct = default);
}

public class AdminUserService : IAdminUserService
{
    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 25;

    private readonly IFirebaseUserManagementService _firebase;
    private readonly IAuditLogService _audit;
    private readonly ICurrentUser _currentUser;

    public AdminUserService(IFirebaseUserManagementService firebase, IAuditLogService audit, ICurrentUser currentUser)
    {
        _firebase = firebase;
        _audit = audit;
        _currentUser = currentUser;
    }

    public Task<UserPageDto> ListAsync(string? query, string? pageToken, int pageSize, CancellationToken ct = default)
    {
        var size = pageSize <= 0 ? DefaultPageSize : Math.Min(pageSize, MaxPageSize);
        return _firebase.ListAsync(query, pageToken, size, ct);
    }

    public Task<AdminUserDto?> GetAsync(string uid, CancellationToken ct = default) =>
        _firebase.GetByUidAsync(uid, ct);

    public async Task<CreateUserResultDto> CreateAsync(CreateUserDto dto, CancellationToken ct = default)
    {
        var role = NormalizeRole(dto.Role);
        var email = (dto.Email ?? "").Trim();
        var name = (dto.Name ?? "").Trim();
        if (string.IsNullOrWhiteSpace(email)) throw new DomainException("El correo es obligatorio.");
        if (string.IsNullOrWhiteSpace(name)) throw new DomainException("El nombre es obligatorio.");

        var existing = await _firebase.GetByEmailAsync(email, ct);
        if (existing is not null)
            throw new DomainException("Ya existe un usuario con ese correo.");

        var user = await _firebase.CreateAsync(name, email, role, ct);
        var link = await _firebase.GeneratePasswordResetLinkAsync(email, ct);

        await _audit.LogAsync(AuditActions.UserCreated, user.Uid, $"role: {role}", ct);
        return new CreateUserResultDto(user, link);
    }

    public async Task<AdminUserDto> UpdateAsync(string uid, UpdateUserDto dto, CancellationToken ct = default)
    {
        var user = await Require(uid, ct);
        var result = user;

        if (!string.IsNullOrWhiteSpace(dto.Name) && dto.Name.Trim() != user.Name)
        {
            result = await _firebase.UpdateNameAsync(uid, dto.Name.Trim(), ct);
            await _audit.LogAsync(AuditActions.UserNameChanged, uid, null, ct);
        }

        if (!string.IsNullOrWhiteSpace(dto.Role))
        {
            var newRole = NormalizeRole(dto.Role);
            if (!string.Equals(newRole, user.Role, StringComparison.OrdinalIgnoreCase))
            {
                // Proteger: no degradar al último administrador activo.
                if (IsAdmin(user.Role) && !IsAdmin(newRole))
                    await EnsureNotLastActiveAdmin(user, "degradar", ct);

                result = await _firebase.SetRoleAsync(uid, newRole, ct);
                await _audit.LogAsync(AuditActions.UserRoleChanged, uid, $"{user.Role ?? "—"} -> {newRole}", ct);
            }
        }

        return result;
    }

    public async Task<AdminUserDto> SetStatusAsync(string uid, bool disabled, CancellationToken ct = default)
    {
        var user = await Require(uid, ct);

        // Proteger: no bloquear al último administrador activo.
        if (disabled && IsAdmin(user.Role) && !user.Disabled)
            await EnsureNotLastActiveAdmin(user, "bloquear", ct);

        var result = await _firebase.SetDisabledAsync(uid, disabled, ct);
        await _audit.LogAsync(AuditActions.UserStatusChanged, uid, disabled ? "bloqueado" : "reactivado", ct);
        return result;
    }

    public async Task RevokeSessionsAsync(string uid, CancellationToken ct = default)
    {
        await Require(uid, ct);
        await _firebase.RevokeSessionsAsync(uid, ct);
        await _audit.LogAsync(AuditActions.UserSessionsRevoked, uid, null, ct);
    }

    public async Task<ActivationLinkDto> GenerateActivationLinkAsync(string uid, CancellationToken ct = default)
    {
        var user = await Require(uid, ct);
        if (string.IsNullOrWhiteSpace(user.Email))
            throw new DomainException("El usuario no tiene correo para generar el enlace.");

        var link = await _firebase.GeneratePasswordResetLinkAsync(user.Email, ct);
        // NUNCA se audita el contenido del enlace.
        await _audit.LogAsync(AuditActions.UserActivationLink, uid, null, ct);
        return new ActivationLinkDto(link);
    }

    // ---------- helpers ----------

    private async Task<AdminUserDto> Require(string uid, CancellationToken ct) =>
        await _firebase.GetByUidAsync(uid, ct) ?? throw new DomainException("El usuario no existe.");

    private async Task EnsureNotLastActiveAdmin(AdminUserDto target, string verb, CancellationToken ct)
    {
        var activeAdmins = await _firebase.CountActiveAdminsAsync(ct);
        // El objetivo es un admin activo, así que cuenta como uno de los activos.
        if (activeAdmins <= 1)
            throw new DomainException($"No se puede {verb} al último administrador activo.");
    }

    private static bool IsAdmin(string? role) =>
        string.Equals(role, Roles.Admin, StringComparison.OrdinalIgnoreCase);

    private static string NormalizeRole(string? role)
    {
        var r = (role ?? "").Trim().ToLowerInvariant();
        if (r != Roles.Admin && r != Roles.Operator)
            throw new DomainException("Rol inválido. Use 'admin' u 'operator'.");
        return r;
    }
}

/// <summary>Roles válidos (duplicado mínimo para no acoplar Application a la capa Api).</summary>
internal static class Roles
{
    public const string Admin = "admin";
    public const string Operator = "operator";
}
