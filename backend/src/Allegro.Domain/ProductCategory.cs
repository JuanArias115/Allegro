namespace Allegro.Domain;

/// <summary>
/// Categoría de producto, administrable en base de datos (antes era un enum fijo).
/// </summary>
public class ProductCategory
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name { get; set; } = string.Empty;

    /// <summary>Orden de presentación en el catálogo.</summary>
    public int DisplayOrder { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<Product> Products { get; set; } = new List<Product>();
}
