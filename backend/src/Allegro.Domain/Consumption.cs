namespace Allegro.Domain;

/// <summary>
/// Consumo adicional cargado a una reserva. El precio unitario se congela en el
/// momento del consumo y no cambia aunque luego se modifique el precio de catálogo.
/// </summary>
public class Consumption
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ReservationId { get; set; }
    public Reservation? Reservation { get; set; }

    public Guid ProductId { get; set; }
    public Product? Product { get; set; }

    /// <summary>Nombre del producto al momento del consumo (instantánea histórica).</summary>
    public string ProductName { get; set; } = string.Empty;

    public int Quantity { get; set; }

    /// <summary>Precio unitario congelado en el momento del consumo.</summary>
    public decimal UnitPrice { get; set; }

    /// <summary>Subtotal = Quantity * UnitPrice.</summary>
    public decimal Subtotal => Quantity * UnitPrice;

    /// <summary>Momento del consumo, almacenado en UTC.</summary>
    public DateTime ConsumedAt { get; set; }
}
