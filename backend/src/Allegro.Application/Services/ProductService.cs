using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Application.Services;

public interface IProductService
{
    Task<IReadOnlyList<ProductDto>> GetAllAsync(bool onlyActive, CancellationToken ct = default);
    Task<ProductDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<ProductDto> CreateAsync(UpsertProductDto dto, CancellationToken ct = default);
    Task<ProductDto> UpdateAsync(Guid id, UpsertProductDto dto, CancellationToken ct = default);
}

public class ProductService : IProductService
{
    private readonly IAppDbContext _db;

    public ProductService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<ProductDto>> GetAllAsync(bool onlyActive, CancellationToken ct = default)
    {
        var query = _db.Products.AsNoTracking()
            .Include(p => p.Category)
            .OrderBy(p => p.Category!.DisplayOrder).ThenBy(p => p.Name).AsQueryable();
        if (onlyActive) query = query.Where(p => p.IsActive);
        var list = await query.ToListAsync(ct);
        return list.Select(p => p.ToDto()).ToList();
    }

    public async Task<ProductDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var product = await _db.Products.AsNoTracking()
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == id, ct);
        return product?.ToDto();
    }

    public async Task<ProductDto> CreateAsync(UpsertProductDto dto, CancellationToken ct = default)
    {
        // Categoría nueva: debe existir y estar activa.
        var category = await ResolveCategoryAsync(dto.CategoryId, requireActive: true, ct);

        var product = new Product
        {
            Name = dto.Name.Trim(),
            ProductCategoryId = category.Id,
            Category = category,
            CurrentPrice = dto.CurrentPrice,
            IsActive = dto.IsActive,
            ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim()
        };
        _db.Products.Add(product);
        await _db.SaveChangesAsync(ct);
        return product.ToDto();
    }

    public async Task<ProductDto> UpdateAsync(Guid id, UpsertProductDto dto, CancellationToken ct = default)
    {
        var product = await _db.Products
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new DomainException("El producto no existe.");

        // Si cambia de categoría, la nueva debe estar activa. Si conserva la misma,
        // se permite aunque esa categoría se haya desactivado.
        var changingCategory = dto.CategoryId != product.ProductCategoryId;
        var category = await ResolveCategoryAsync(dto.CategoryId, requireActive: changingCategory, ct);

        product.Name = dto.Name.Trim();
        product.ProductCategoryId = category.Id;
        product.Category = category;
        product.CurrentPrice = dto.CurrentPrice;
        product.IsActive = dto.IsActive;
        product.ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim();

        await _db.SaveChangesAsync(ct);
        return product.ToDto();
    }

    private async Task<ProductCategory> ResolveCategoryAsync(Guid categoryId, bool requireActive, CancellationToken ct)
    {
        var category = await _db.ProductCategories.FirstOrDefaultAsync(c => c.Id == categoryId, ct)
            ?? throw new DomainException("La categoría seleccionada no existe.");
        if (requireActive && !category.IsActive)
            throw new DomainException("La categoría seleccionada no está activa.");
        return category;
    }
}
