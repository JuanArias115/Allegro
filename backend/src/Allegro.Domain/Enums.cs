namespace Allegro.Domain;

/// <summary>Estados permitidos de una reserva.</summary>
public enum ReservationStatus
{
    Confirmed = 0,   // Confirmada
    CheckedIn = 1,   // Hospedada
    Completed = 2,   // Finalizada
    Cancelled = 3    // Cancelada
}

/// <summary>Métodos de pago básicos para los abonos.</summary>
public enum PaymentMethod
{
    Cash = 0,        // Efectivo
    Transfer = 1,    // Transferencia
    Other = 2        // Otro
}

// Las categorías de producto ya no son un enum fijo: ahora son una entidad
// dinámica (ver ProductCategory.cs) almacenada en base de datos.
