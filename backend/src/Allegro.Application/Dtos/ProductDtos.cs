using Allegro.Domain;

namespace Allegro.Application.Dtos;

public record ProductCategoryDto(
    Guid Id,
    string Name,
    int DisplayOrder,
    bool IsActive);

public record ProductDto(
    Guid Id,
    string Name,
    Guid CategoryId,
    string CategoryName,
    decimal CurrentPrice,
    bool IsActive,
    string? ImageUrl);

public record UpsertProductDto(
    string Name,
    Guid CategoryId,
    decimal CurrentPrice,
    bool IsActive,
    string? ImageUrl);

public static class ProductMapping
{
    public static ProductCategoryDto ToDto(this ProductCategory c) =>
        new(c.Id, c.Name, c.DisplayOrder, c.IsActive);

    public static ProductDto ToDto(this Product p) =>
        new(p.Id, p.Name, p.ProductCategoryId, p.Category?.Name ?? string.Empty,
            p.CurrentPrice, p.IsActive, p.ImageUrl);
}
