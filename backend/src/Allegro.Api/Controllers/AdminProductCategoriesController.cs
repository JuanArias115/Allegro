using Allegro.Api.Auth;
using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Allegro.Api.Controllers;

/// <summary>
/// Administración de categorías de productos (crear, editar, ordenar, activar/
/// desactivar). Solo administradores. El endpoint público GET /api/product-categories
/// (categorías activas, usado por Flutter) NO cambia.
/// </summary>
[ApiController]
[Authorize(Policy = Policies.Admin)]
[Route("api/admin/product-categories")]
public class AdminProductCategoriesController : ControllerBase
{
    private readonly IProductCategoryService _service;

    public AdminProductCategoriesController(IProductCategoryService service) => _service = service;

    /// <summary>Todas las categorías, incluidas las inactivas.</summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ProductCategoryDto>>> GetAll(CancellationToken ct)
        => Ok(await _service.GetAllAsync(ct));

    [HttpPost]
    public async Task<ActionResult<ProductCategoryDto>> Create(UpsertProductCategoryDto dto, CancellationToken ct)
        => Ok(await _service.CreateAsync(dto, ct));

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ProductCategoryDto>> Update(Guid id, UpsertProductCategoryDto dto, CancellationToken ct)
        => Ok(await _service.UpdateAsync(id, dto, ct));
}
