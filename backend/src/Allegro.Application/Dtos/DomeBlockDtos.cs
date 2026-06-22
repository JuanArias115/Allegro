namespace Allegro.Application.Dtos;

public record DomeBlockDto(
    Guid Id,
    Guid DomeId,
    string DomeName,
    DateOnly StartDate,
    DateOnly EndDate,
    string Reason,
    DateTime CreatedAt);

/// <summary>Rango inicio inclusivo, fin exclusivo (igual que las reservas).</summary>
public record CreateDomeBlockDto(
    Guid DomeId,
    DateOnly StartDate,
    DateOnly EndDate,
    string Reason);
