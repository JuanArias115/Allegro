using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;
using FirebaseAdmin.Auth;

namespace Allegro.Infrastructure.Firebase;

/// <summary>
/// Implementación de gestión de usuarios sobre Firebase Admin SDK. Devuelve DTOs
/// propios (nunca objetos del SDK) y sanea los errores del SDK como
/// <see cref="DomainException"/> para no filtrar detalles internos.
///
/// La búsqueda y la paginación se resuelven en memoria sobre el conjunto de
/// usuarios (acotado): el caso de uso es un equipo pequeño de administración.
/// </summary>
public class FirebaseUserManagementService : IFirebaseUserManagementService
{
    private const int HardEnumerationCap = 1000;
    private const string ClaimAppAccess = "app_access";
    private const string ClaimRole = "role";

    private static FirebaseAuth Auth => FirebaseAuth.DefaultInstance;

    public async Task<UserPageDto> ListAsync(string? query, string? pageToken, int pageSize, CancellationToken ct = default)
    {
        var all = await EnumerateAsync(ct);

        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLowerInvariant();
            all = all.Where(u =>
                (u.Email ?? "").ToLowerInvariant().Contains(q) ||
                (u.Name ?? "").ToLowerInvariant().Contains(q)).ToList();
        }

        all = all.OrderBy(u => u.Email ?? u.Uid, StringComparer.OrdinalIgnoreCase).ToList();

        var offset = ParseOffset(pageToken);
        var page = all.Skip(offset).Take(pageSize).ToList();
        var nextOffset = offset + page.Count;
        var next = nextOffset < all.Count ? nextOffset.ToString() : null;

        return new UserPageDto(page, next);
    }

    public async Task<AdminUserDto?> GetByUidAsync(string uid, CancellationToken ct = default)
    {
        try
        {
            var user = await Auth.GetUserAsync(uid, ct);
            return Map(user);
        }
        catch (FirebaseAuthException)
        {
            return null;
        }
    }

    public async Task<AdminUserDto?> GetByEmailAsync(string email, CancellationToken ct = default)
    {
        try
        {
            var user = await Auth.GetUserByEmailAsync(email, ct);
            return Map(user);
        }
        catch (FirebaseAuthException)
        {
            return null;
        }
    }

    public async Task<AdminUserDto> CreateAsync(string name, string email, string role, CancellationToken ct = default)
    {
        try
        {
            var created = await Auth.CreateUserAsync(new UserRecordArgs
            {
                Email = email,
                DisplayName = name,
                EmailVerified = false,
                Disabled = false,
            }, ct);

            await Auth.SetCustomUserClaimsAsync(created.Uid, BuildClaims(role), ct);
            var fresh = await Auth.GetUserAsync(created.Uid, ct);
            return Map(fresh);
        }
        catch (FirebaseAuthException ex)
        {
            throw Sanitize(ex, "No se pudo crear el usuario.");
        }
    }

    public async Task<AdminUserDto> UpdateNameAsync(string uid, string name, CancellationToken ct = default)
    {
        try
        {
            var updated = await Auth.UpdateUserAsync(new UserRecordArgs { Uid = uid, DisplayName = name }, ct);
            return Map(updated);
        }
        catch (FirebaseAuthException ex)
        {
            throw Sanitize(ex, "No se pudo actualizar el usuario.");
        }
    }

    public async Task<AdminUserDto> SetRoleAsync(string uid, string role, CancellationToken ct = default)
    {
        try
        {
            await Auth.SetCustomUserClaimsAsync(uid, BuildClaims(role), ct);
            var fresh = await Auth.GetUserAsync(uid, ct);
            return Map(fresh);
        }
        catch (FirebaseAuthException ex)
        {
            throw Sanitize(ex, "No se pudo cambiar el rol.");
        }
    }

    public async Task<AdminUserDto> SetDisabledAsync(string uid, bool disabled, CancellationToken ct = default)
    {
        try
        {
            var updated = await Auth.UpdateUserAsync(new UserRecordArgs { Uid = uid, Disabled = disabled }, ct);
            return Map(updated);
        }
        catch (FirebaseAuthException ex)
        {
            throw Sanitize(ex, "No se pudo cambiar el estado del usuario.");
        }
    }

    public async Task RevokeSessionsAsync(string uid, CancellationToken ct = default)
    {
        try
        {
            await Auth.RevokeRefreshTokensAsync(uid, ct);
        }
        catch (FirebaseAuthException ex)
        {
            throw Sanitize(ex, "No se pudieron revocar las sesiones.");
        }
    }

    public async Task<string> GeneratePasswordResetLinkAsync(string email, CancellationToken ct = default)
    {
        try
        {
            return await Auth.GeneratePasswordResetLinkAsync(email);
        }
        catch (FirebaseAuthException ex)
        {
            throw Sanitize(ex, "No se pudo generar el enlace de activación.");
        }
    }

    public async Task<int> CountActiveAdminsAsync(CancellationToken ct = default)
    {
        var all = await EnumerateAsync(ct);
        return all.Count(u => !u.Disabled &&
            string.Equals(u.Role, "admin", StringComparison.OrdinalIgnoreCase));
    }

    // ---------- helpers ----------

    private static async Task<List<AdminUserDto>> EnumerateAsync(CancellationToken ct)
    {
        var result = new List<AdminUserDto>();
        var pageEnumerable = Auth.ListUsersAsync(null);
        await foreach (var user in pageEnumerable.WithCancellation(ct))
        {
            result.Add(Map(user));
            if (result.Count >= HardEnumerationCap) break;
        }
        return result;
    }

    private static IReadOnlyDictionary<string, object> BuildClaims(string role) =>
        new Dictionary<string, object> { [ClaimAppAccess] = true, [ClaimRole] = role };

    private static AdminUserDto Map(UserRecord u)
    {
        string? role = null;
        if (u.CustomClaims is not null && u.CustomClaims.TryGetValue(ClaimRole, out var r) && r is string rs)
            role = rs;

        var provider = u.ProviderData is { Length: > 0 }
            ? u.ProviderData[0].ProviderId
            : "firebase";

        return new AdminUserDto(
            Uid: u.Uid,
            Name: u.DisplayName,
            Email: u.Email,
            Provider: provider,
            Role: role,
            Disabled: u.Disabled,
            CreatedAtUtc: u.UserMetaData?.CreationTimestamp,
            LastLoginAtUtc: u.UserMetaData?.LastSignInTimestamp);
    }

    private static int ParseOffset(string? pageToken) =>
        int.TryParse(pageToken, out var n) && n > 0 ? n : 0;

    // No exponemos el mensaje del SDK al cliente: registramos un mensaje propio.
    private static DomainException Sanitize(FirebaseAuthException ex, string message) =>
        new($"{message}");
}
