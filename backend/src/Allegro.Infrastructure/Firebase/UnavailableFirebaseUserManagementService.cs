using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;

namespace Allegro.Infrastructure.Firebase;

/// <summary>
/// Implementación usada cuando AUTH_MODE != firebase (desarrollo local sin
/// credenciales de Firebase Admin). El listado devuelve vacío y cualquier
/// operación de escritura informa con claridad que no está disponible.
/// </summary>
public class UnavailableFirebaseUserManagementService : IFirebaseUserManagementService
{
    private const string Message =
        "La gestión de usuarios requiere AUTH_MODE=firebase y credenciales de Firebase Admin.";

    public Task<UserPageDto> ListAsync(string? query, string? pageToken, int pageSize, CancellationToken ct = default) =>
        Task.FromResult(new UserPageDto(Array.Empty<AdminUserDto>(), null));

    public Task<AdminUserDto?> GetByUidAsync(string uid, CancellationToken ct = default) =>
        Task.FromResult<AdminUserDto?>(null);

    public Task<AdminUserDto?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        Task.FromResult<AdminUserDto?>(null);

    public Task<AdminUserDto> CreateAsync(string name, string email, string role, CancellationToken ct = default) =>
        throw new DomainException(Message);

    public Task<AdminUserDto> UpdateNameAsync(string uid, string name, CancellationToken ct = default) =>
        throw new DomainException(Message);

    public Task<AdminUserDto> SetRoleAsync(string uid, string role, CancellationToken ct = default) =>
        throw new DomainException(Message);

    public Task<AdminUserDto> SetDisabledAsync(string uid, bool disabled, CancellationToken ct = default) =>
        throw new DomainException(Message);

    public Task RevokeSessionsAsync(string uid, CancellationToken ct = default) =>
        throw new DomainException(Message);

    public Task<string> GeneratePasswordResetLinkAsync(string email, CancellationToken ct = default) =>
        throw new DomainException(Message);

    public Task<int> CountActiveAdminsAsync(CancellationToken ct = default) =>
        Task.FromResult(0);
}
