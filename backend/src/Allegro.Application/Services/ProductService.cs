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
            .OrderBy(p => p.Category).ThenBy(p => p.Name).AsQueryable();
        if (onlyActive) query = query.Where(p => p.IsActive);
        var list = await query.ToListAsync(ct);
        return list.Select(p => p.ToDto()).ToList();
    }

    public async Task<ProductDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var product = await _db.Products.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id, ct);
        return product?.ToDto();
    }

    public async Task<ProductDto> CreateAsync(UpsertProductDto dto, CancellationToken ct = default)
    {
        var product = new Product
        {
            Name = dto.Name.Trim(),
            Category = dto.Category,
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
        var product = await _db.Products.FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new DomainException("El producto no existe.");

        product.Name = dto.Name.Trim();
        product.Category = dto.Category;
        product.CurrentPrice = dto.CurrentPrice;
        product.IsActive = dto.IsActive;
        product.ImageUrl = string.IsNullOrWhiteSpace(dto.ImageUrl) ? null : dto.ImageUrl.Trim();

        await _db.SaveChangesAsync(ct);
        return product.ToDto();
    }
}
