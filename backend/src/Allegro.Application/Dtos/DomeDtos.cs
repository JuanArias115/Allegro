using Allegro.Domain;

namespace Allegro.Application.Dtos;

public record DomeDto(
    Guid Id,
    string Name,
    string ShortDescription,
    int MaxCapacity,
    bool IsActive);

public record UpsertDomeDto(
    string Name,
    string ShortDescription,
    int MaxCapacity,
    bool IsActive);

public static class DomeMapping
{
    public static DomeDto ToDto(this Dome d) =>
        new(d.Id, d.Name, d.ShortDescription, d.MaxCapacity, d.IsActive);
}
