using Allegro.Application.Dtos;
using Allegro.Domain;
using Allegro.Infrastructure.Persistence;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

public class ProductCategoryTests
{
    private static UpsertProductDto Product(Guid categoryId, string name = "Café") =>
        new(name, categoryId, 5000m, true, null);

    [Fact]
    public async Task GetActive_returns_only_active_ordered_by_displayOrder_then_name()
    {
        var h = new TestHarness();
        h.AddCategory("Inactiva", 0, active: false); // no debe aparecer
        h.AddCategory("Bravo", 5, active: true);
        h.AddCategory("Alfa", 5, active: true); // mismo DisplayOrder -> ordena por nombre

        var result = await h.Categories().GetActiveAsync();

        result.Should().OnlyContain(c => c.IsActive);
        result.Should().NotContain(c => c.Name == "Inactiva");
        // Las 4 iniciales (orden 1-4) + Alfa/Bravo (orden 5, alfabético).
        result.Select(c => c.Name).Should()
            .ContainInOrder("Bebidas", "Menú", "Snacks", "Servicios", "Alfa", "Bravo");
    }

    [Fact]
    public async Task Create_product_with_valid_category_succeeds()
    {
        var h = new TestHarness();
        var dto = await h.Products().CreateAsync(Product(ProductCategorySeedData.Bebidas));

        dto.CategoryId.Should().Be(ProductCategorySeedData.Bebidas);
        dto.CategoryName.Should().Be("Bebidas");
    }

    [Fact]
    public async Task Edit_product_changes_category()
    {
        var h = new TestHarness();
        var created = await h.Products().CreateAsync(Product(ProductCategorySeedData.Bebidas));

        var updated = await h.Products().UpdateAsync(created.Id,
            Product(ProductCategorySeedData.Menu, name: "Café con leche"));

        updated.Name.Should().Be("Café con leche");
        updated.CategoryId.Should().Be(ProductCategorySeedData.Menu);
        updated.CategoryName.Should().Be("Menú");
    }

    [Fact]
    public async Task Create_with_nonexistent_category_is_rejected()
    {
        var h = new TestHarness();
        var act = async () => await h.Products().CreateAsync(Product(Guid.NewGuid()));
        await act.Should().ThrowAsync<DomainException>().WithMessage("*no existe*");
    }

    [Fact]
    public async Task Create_with_inactive_category_is_rejected()
    {
        var h = new TestHarness();
        var inactive = h.AddCategory("Descontinuada", 9, active: false);
        var act = async () => await h.Products().CreateAsync(Product(inactive.Id));
        await act.Should().ThrowAsync<DomainException>().WithMessage("*no está activa*");
    }

    [Theory]
    [InlineData(0, "Botella de vino", "Bebidas")]
    [InlineData(2, "Late checkout", "Servicios")]
    [InlineData(1, "Galletas Tosh", "Snacks")]
    [InlineData(1, "Gomitas Trolli", "Snacks")]
    [InlineData(1, "Pizza", "Menú")]
    [InlineData(1, "Churrasco", "Menú")]
    [InlineData(3, "Algo raro", "Menú")]
    public void Legacy_migration_maps_each_product_to_a_category(int oldCategory, string name, string expected)
    {
        var id = ProductCategorySeedData.ResolveLegacyCategory(oldCategory, name);

        // Ningún producto queda sin categoría: siempre cae en una de las cuatro.
        var match = ProductCategorySeedData.Initial.Single(c => c.Id == id);
        match.Name.Should().Be(expected);
    }
}
