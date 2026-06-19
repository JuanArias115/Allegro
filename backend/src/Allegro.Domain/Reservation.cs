namespace Allegro.Domain;

/// <summary>
/// Reserva de un domo. Mantiene el historial de abonos y consumos y calcula
/// automáticamente los totales y el saldo pendiente.
/// </summary>
public class Reservation
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string GuestName { get; set; } = string.Empty;

    /// <summary>Teléfono o número de WhatsApp del huésped.</summary>
    public string Phone { get; set; } = string.Empty;

    public Guid DomeId { get; set; }
    public Dome? Dome { get; set; }

    /// <summary>Fecha de llegada (calendario).</summary>
    public DateOnly CheckIn { get; set; }

    /// <summary>Fecha de salida (calendario). Debe ser posterior a la llegada.</summary>
    public DateOnly CheckOut { get; set; }

    public int GuestCount { get; set; }

    /// <summary>Precio total del alojamiento. No incluye consumos.</summary>
    public decimal LodgingPrice { get; set; }

    public ReservationStatus Status { get; set; } = ReservationStatus.Confirmed;

    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
    public ICollection<Consumption> Consumptions { get; set; } = new List<Consumption>();

    // ----- Cálculos de negocio (no se persisten) -----

    /// <summary>Suma de todos los abonos recibidos.</summary>
    public decimal TotalPaid => Payments.Sum(p => p.Amount);

    /// <summary>Suma de todos los consumos adicionales.</summary>
    public decimal TotalConsumptions => Consumptions.Sum(c => c.Subtotal);

    /// <summary>Total a cobrar = alojamiento + consumos.</summary>
    public decimal TotalDue => LodgingPrice + TotalConsumptions;

    /// <summary>Saldo pendiente = alojamiento + consumos - abonos.</summary>
    public decimal Balance => TotalDue - TotalPaid;

    /// <summary>Una reserva cancelada no bloquea disponibilidad.</summary>
    public bool BlocksAvailability =>
        Status != ReservationStatus.Cancelled;

    /// <summary>Verdadero si esta reserva se cruza con el rango dado en el mismo domo.</summary>
    public bool OverlapsWith(DateOnly checkIn, DateOnly checkOut) =>
        BlocksAvailability && CheckIn < checkOut && checkIn < CheckOut;
}
