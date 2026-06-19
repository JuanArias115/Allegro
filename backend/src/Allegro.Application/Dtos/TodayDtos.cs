namespace Allegro.Application.Dtos;

/// <summary>Estado del día para la pantalla "Hoy".</summary>
public record TodayDto(
    DateOnly Date,
    IReadOnlyList<ReservationSummaryDto> Arrivals,
    IReadOnlyList<ReservationSummaryDto> Departures,
    IReadOnlyList<ReservationSummaryDto> CurrentlyHosted,
    IReadOnlyList<ReservationSummaryDto> Upcoming);

/// <summary>Disponibilidad de un domo para un rango de fechas.</summary>
public record AvailabilityDto(
    Guid DomeId,
    DateOnly CheckIn,
    DateOnly CheckOut,
    bool IsAvailable,
    IReadOnlyList<ReservationSummaryDto> Conflicts);
