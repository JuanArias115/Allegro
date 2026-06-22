using Allegro.Application.Abstractions;
using Allegro.Application.Services;

namespace Allegro.Tests.Fakes;

public sealed class FakeCurrentUser : ICurrentUser
{
    public string? Uid { get; set; } = "actor-uid";
    public string? Name { get; set; } = "Actor";
    public string? Role { get; set; } = "admin";
    public bool IsAuthenticated => true;
}

public sealed class FakeAuditLogService : IAuditLogService
{
    public record Entry(string Action, string? TargetId, string? Detail);

    public List<Entry> Entries { get; } = new();

    public Task LogAsync(string action, string? targetId, string? detail, CancellationToken ct = default)
    {
        Entries.Add(new Entry(action, targetId, detail));
        return Task.CompletedTask;
    }
}
