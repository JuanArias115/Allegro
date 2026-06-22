namespace Allegro.Application.Abstractions;

/// <summary>Reloj abstraído para poder probar la lógica que depende de la fecha/hora.</summary>
public interface IClock
{
    /// <summary>Momento actual en UTC.</summary>
    DateTime UtcNow { get; }

    /// <summary>Fecha "de hoy" en la zona horaria de operación del negocio.</summary>
    DateOnly Today { get; }

    /// <summary>Convierte un instante UTC a la fecha calendario en la zona del negocio (America/Bogota).</summary>
    DateOnly ToBusinessDate(DateTime utc);
}
