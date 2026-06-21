using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Application.Services;

public interface IProductCategoryService
{
    /// <summary>Categorías activas, ordenadas por DisplayOrder y luego por Name.</summary>
    Task<IReadOnlyList<ProductCategoryDto>> GetActiveAsync(CancellationToken ct = default);

    /// <summary>Todas las categorías (incluye inactivas) para administración.</summary>
    Task<IReadOnlyList<ProductCategoryDto>> GetAllAsync(CancellationToken ct = default);

    Task<ProductCategoryDto> CreateAsync(UpsertProductCategoryDto dto, CancellationToken ct = default);
    Task<ProductCategoryDto> UpdateAsync(Guid id, UpsertProductCategoryDto dto, CancellationToken ct = default);
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

    public async Task<IReadOnlyList<ProductCategoryDto>> GetAllAsync(CancellationToken ct = default)
    {
        var list = await _db.ProductCategories.AsNoTracking()
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.Name)
            .ToListAsync(ct);
        return list.Select(c => c.ToDto()).ToList();
    }

    public async Task<ProductCategoryDto> CreateAsync(UpsertProductCategoryDto dto, CancellationToken ct = default)
    {
        var name = dto.Name.Trim();
        await EnsureNameAvailableAsync(name, excludeId: null, ct);

        var category = new ProductCategory
        {
            Name = name,
            DisplayOrder = dto.DisplayOrder,
            IsActive = dto.IsActive,
        };
        _db.ProductCategories.Add(category);
        await _db.SaveChangesAsync(ct);
        return category.ToDto();
    }

    public async Task<ProductCategoryDto> UpdateAsync(Guid id, UpsertProductCategoryDto dto, CancellationToken ct = default)
    {
        var category = await _db.ProductCategories.FirstOrDefaultAsync(c => c.Id == id, ct)
            ?? throw new DomainException("La categoría no existe.");

        var name = dto.Name.Trim();
        await EnsureNameAvailableAsync(name, excludeId: id, ct);

        // Si se desactiva, no debe quedar con productos activos asignados.
        if (!dto.IsActive && category.IsActive)
        {
            var hasActiveProducts = await _db.Products.AsNoTracking()
                .AnyAsync(p => p.ProductCategoryId == id && p.IsActive, ct);
            if (hasActiveProducts)
                throw new DomainException("No se puede desactivar una categoría con productos activos.");
        }

        category.Name = name;
        category.DisplayOrder = dto.DisplayOrder;
        category.IsActive = dto.IsActive;
        await _db.SaveChangesAsync(ct);
        return category.ToDto();
    }

    private async Task EnsureNameAvailableAsync(string name, Guid? excludeId, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("El nombre de la categoría es obligatorio.");

        var exists = await _db.ProductCategories.AsNoTracking()
            .AnyAsync(c => c.Name.ToLower() == name.ToLower() && (excludeId == null || c.Id != excludeId), ct);
        if (exists)
            throw new DomainException("Ya existe una categoría con ese nombre.");
    }
}
