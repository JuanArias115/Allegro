namespace Allegro.Domain;

/// <summary>
/// Error de regla de negocio. La capa de API lo traduce a una respuesta 400/409
/// con un mensaje claro para el cliente.
/// </summary>
public class DomainException : Exception
{
    public DomainException(string message) : base(message) { }
}
