using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Allegro.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/product-categories")]
public class ProductCategoriesController : ControllerBase
{
    private readonly IProductCategoryService _service;

    public ProductCategoriesController(IProductCategoryService service) => _service = service;

    /// <summary>Categorías activas, ordenadas por DisplayOrder y luego por Name.</summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ProductCategoryDto>>> GetActive(CancellationToken ct)
        => Ok(await _service.GetActiveAsync(ct));
}
