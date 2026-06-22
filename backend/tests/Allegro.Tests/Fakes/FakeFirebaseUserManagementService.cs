using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;

namespace Allegro.Tests.Fakes;

/// <summary>
/// Implementación en memoria de <see cref="IFirebaseUserManagementService"/> para
/// pruebas. NO se conecta a Firebase. Permite verificar las reglas de negocio del
/// <c>AdminUserService</c> (protección del último admin, etc.).
/// </summary>
public sealed class FakeFirebaseUserManagementService : IFirebaseUserManagementService
{
    private readonly Dictionary<string, AdminUserDto> _users = new();
    private int _seq;

    public List<string> ResetLinksGenerated { get; } = new();

    public AdminUserDto Seed(string name, string email, string role, bool disabled = false)
    {
        var uid = $"uid-{++_seq}";
        var user = new AdminUserDto(uid, name, email, "password", role, disabled,
            new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc), null);
        _users[uid] = user;
        return user;
    }

    public Task<UserPageDto> ListAsync(string? query, string? pageToken, int pageSize, CancellationToken ct = default)
    {
        IEnumerable<AdminUserDto> items = _users.Values;
        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLowerInvariant();
            items = items.Where(u => (u.Email ?? "").ToLowerInvariant().Contains(q)
                                     || (u.Name ?? "").ToLowerInvariant().Contains(q));
        }
        var ordered = items.OrderBy(u => u.Email).ToList();
        var offset = int.TryParse(pageToken, out var n) ? n : 0;
        var page = ordered.Skip(offset).Take(pageSize).ToList();
        var nextOffset = offset + page.Count;
        var next = nextOffset < ordered.Count ? nextOffset.ToString() : null;
        return Task.FromResult(new UserPageDto(page, next));
    }

    public Task<AdminUserDto?> GetByUidAsync(string uid, CancellationToken ct = default) =>
        Task.FromResult(_users.TryGetValue(uid, out var u) ? u : null);

    public Task<AdminUserDto?> GetByEmailAsync(string email, CancellationToken ct = default) =>
        Task.FromResult(_users.Values.FirstOrDefault(u =>
            string.Equals(u.Email, email, StringComparison.OrdinalIgnoreCase)));

    public Task<AdminUserDto> CreateAsync(string name, string email, string role, CancellationToken ct = default) =>
        Task.FromResult(Seed(name, email, role));

    public Task<AdminUserDto> UpdateNameAsync(string uid, string name, CancellationToken ct = default)
    {
        var u = _users[uid] with { Name = name };
        _users[uid] = u;
        return Task.FromResult(u);
    }

    public Task<AdminUserDto> SetRoleAsync(string uid, string role, CancellationToken ct = default)
    {
        var u = _users[uid] with { Role = role };
        _users[uid] = u;
        return Task.FromResult(u);
    }

    public Task<AdminUserDto> SetDisabledAsync(string uid, bool disabled, CancellationToken ct = default)
    {
        var u = _users[uid] with { Disabled = disabled };
        _users[uid] = u;
        return Task.FromResult(u);
    }

    public Task RevokeSessionsAsync(string uid, CancellationToken ct = default) => Task.CompletedTask;

    public Task<string> GeneratePasswordResetLinkAsync(string email, CancellationToken ct = default)
    {
        var link = $"https://example.test/reset?email={email}";
        ResetLinksGenerated.Add(link);
        return Task.FromResult(link);
    }

    public Task<int> CountActiveAdminsAsync(CancellationToken ct = default) =>
        Task.FromResult(_users.Values.Count(u => !u.Disabled &&
            string.Equals(u.Role, "admin", StringComparison.OrdinalIgnoreCase)));
}
