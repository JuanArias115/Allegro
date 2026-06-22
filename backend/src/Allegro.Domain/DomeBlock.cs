namespace Allegro.Domain;

/// <summary>
/// Bloqueo de fechas de un domo por mantenimiento o uso personal. Impide crear
/// reservas que se crucen con el rango. El rango usa la misma semántica que las
/// reservas: <see cref="StartDate"/> inclusivo, <see cref="EndDate"/> exclusivo.
/// </summary>
public class DomeBlock
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DomeId { get; set; }
    public Dome? Dome { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public string Reason { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    /// <summary>Cruce de intervalos [start, end) con otro rango.</summary>
    public bool OverlapsWith(DateOnly start, DateOnly end) =>
        StartDate < end && start < EndDate;
}
