using Allegro.Domain;

namespace Allegro.Application.Dtos;

public record ProductDto(
    Guid Id,
    string Name,
    ProductCategory Category,
    decimal CurrentPrice,
    bool IsActive,
    string? ImageUrl);

public record UpsertProductDto(
    string Name,
    ProductCategory Category,
    decimal CurrentPrice,
    bool IsActive,
    string? ImageUrl);

public static class ProductMapping
{
    public static ProductDto ToDto(this Product p) =>
        new(p.Id, p.Name, p.Category, p.CurrentPrice, p.IsActive, p.ImageUrl);
}
