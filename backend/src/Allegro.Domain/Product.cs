namespace Allegro.Domain;

/// <summary>
/// Producto o servicio adicional del catálogo. Su precio actual puede cambiar
/// con el tiempo; los consumos guardan el precio histórico por separado.
/// </summary>
public class Product
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name { get; set; } = string.Empty;

    /// <summary>Categoría dinámica (clave foránea, obligatoria).</summary>
    public Guid ProductCategoryId { get; set; }
    public ProductCategory? Category { get; set; }

    /// <summary>Precio actual de catálogo. No puede ser negativo.</summary>
    public decimal CurrentPrice { get; set; }

    public bool IsActive { get; set; } = true;

    /// <summary>URL opcional de la imagen del producto.</summary>
    public string? ImageUrl { get; set; }
}
