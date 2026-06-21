namespace Allegro.Infrastructure.Persistence;

/// <summary>
/// Categorías iniciales (UUIDs conocidos) y la regla de migración de los valores
/// del antiguo enum. La migración EF Core y las pruebas comparten estas constantes
/// para mantenerse sincronizadas.
/// </summary>
public static class ProductCategorySeedData
{
    public static readonly Guid Bebidas = Guid.Parse("c0000000-0000-0000-0000-000000000001");
    public static readonly Guid Menu = Guid.Parse("c0000000-0000-0000-0000-000000000002");
    public static readonly Guid Snacks = Guid.Parse("c0000000-0000-0000-0000-000000000003");
    public static readonly Guid Servicios = Guid.Parse("c0000000-0000-0000-0000-000000000004");

    /// <summary>(Id, Nombre, DisplayOrder) de las cuatro categorías iniciales.</summary>
    public static readonly IReadOnlyList<(Guid Id, string Name, int Order)> Initial = new[]
    {
        (Bebidas, "Bebidas", 1),
        (Menu, "Menú", 2),
        (Snacks, "Snacks", 3),
        (Servicios, "Servicios", 4),
    };

    /// <summary>Productos de la antigua categoría "Alimentos" (1) que pasan a Snacks.</summary>
    public static readonly IReadOnlyList<string> SnackNames = new[]
    {
        "Galletas Tosh",
        "Chocolatina Jumbo Maní",
        "Mix de arándanos",
        "Chocolatina Gol",
        "Todo Rico Original",
        "Maíz tostado",
        "Gomitas Trolli",
    };

    /// <summary>
    /// Categoría destino para un producto según su antiguo valor de enum y su nombre.
    /// 0 -> Bebidas, 2 -> Servicios; el resto (1 "Alimentos" y cualquier otro):
    /// Snacks si el nombre está en la lista, si no Menú. Nunca devuelve vacío.
    /// </summary>
    public static Guid ResolveLegacyCategory(int oldCategory, string productName)
    {
        if (oldCategory == 0) return Bebidas;
        if (oldCategory == 2) return Servicios;
        var name = (productName ?? string.Empty).Trim();
        var isSnack = SnackNames.Any(s => string.Equals(s, name, StringComparison.OrdinalIgnoreCase));
        return isSnack ? Snacks : Menu;
    }
}
