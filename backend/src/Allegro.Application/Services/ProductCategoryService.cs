using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Application.Services;

public interface IProductCategoryService
{
    /// <summary>Categorías activas, ordenadas por DisplayOrder y luego por Name.</summary>
    Task<IReadOnlyList<ProductCategoryDto>> GetActiveAsync(CancellationToken ct = default);
}

public class ProductCategoryService : IProductCategoryService
{
    private readonly IAppDbContext _db;

    public ProductCategoryService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<ProductCategoryDto>> GetActiveAsync(CancellationToken ct = default)
    {
        var list = await _db.ProductCategories.AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.Name)
            .ToListAsync(ct);
        return list.Select(c => c.ToDto()).ToList();
    }
}
