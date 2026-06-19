namespace Allegro.Domain;

/// <summary>
/// Un domo del glamping. Inicialmente existen dos, creados mediante datos iniciales.
/// </summary>
public class Dome
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name { get; set; } = string.Empty;

    public string ShortDescription { get; set; } = string.Empty;

    /// <summary>Capacidad máxima de huéspedes.</summary>
    public int MaxCapacity { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}
