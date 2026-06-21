using Allegro.Application.Dtos;
using Allegro.Domain;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

public class CategoryAdminTests
{
    [Fact]
    public async Task Create_category_appears_in_get_all()
    {
        var h = new TestHarness();

        var created = await h.Categories().CreateAsync(new UpsertProductCategoryDto("Postres", 10, true));

        created.Name.Should().Be("Postres");
        var all = await h.Categories().GetAllAsync();
        all.Should().Contain(c => c.Name == "Postres");
    }

    [Fact]
    public async Task Create_rejects_duplicate_name()
    {
        var h = new TestHarness();
        await h.Categories().CreateAsync(new UpsertProductCategoryDto("Postres", 10, true));

        var act = async () => await h.Categories().CreateAsync(new UpsertProductCategoryDto("postres", 11, true));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*ya existe*");
    }

    [Fact]
    public async Task Update_can_reorder_and_rename()
    {
        var h = new TestHarness();
        var c = await h.Categories().CreateAsync(new UpsertProductCategoryDto("Postres", 10, true));

        var updated = await h.Categories().UpdateAsync(c.Id, new UpsertProductCategoryDto("Dulces", 2, true));

        updated.Name.Should().Be("Dulces");
        updated.DisplayOrder.Should().Be(2);
    }

    [Fact]
    public async Task Cannot_deactivate_category_with_active_products()
    {
        var h = new TestHarness();
        var c = await h.Categories().CreateAsync(new UpsertProductCategoryDto("Postres", 10, true));
        h.AddProduct("Flan", 9000m, c.Id);

        var act = async () => await h.Categories().UpdateAsync(c.Id, new UpsertProductCategoryDto("Postres", 10, false));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*productos activos*");
    }

    [Fact]
    public async Task Get_all_includes_inactive_but_get_active_does_not()
    {
        var h = new TestHarness();
        await h.Categories().CreateAsync(new UpsertProductCategoryDto("Inactiva", 20, false));

        (await h.Categories().GetAllAsync()).Should().Contain(c => c.Name == "Inactiva");
        (await h.Categories().GetActiveAsync()).Should().NotContain(c => c.Name == "Inactiva");
    }
}
