namespace Allegro.Domain;

/// <summary>Un abono (pago parcial o total) asociado a una reserva.</summary>
public class Payment
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ReservationId { get; set; }
    public Reservation? Reservation { get; set; }

    /// <summary>Valor del abono. No puede ser negativo.</summary>
    public decimal Amount { get; set; }

    /// <summary>Momento del abono, almacenado en UTC.</summary>
    public DateTime PaidAt { get; set; }

    public PaymentMethod Method { get; set; } = PaymentMethod.Cash;

    public string? Note { get; set; }
}
