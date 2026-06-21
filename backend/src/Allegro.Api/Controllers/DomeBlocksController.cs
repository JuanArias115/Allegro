using Allegro.Api.Auth;
using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Allegro.Api.Controllers;

/// <summary>
/// Bloqueos de fechas por mantenimiento o uso personal. Operación de calendario,
/// disponible para operadores y administradores.
/// </summary>
[ApiController]
[Authorize(Policy = Policies.Operator)]
[Route("api/dome-blocks")]
public class DomeBlocksController : ControllerBase
{
    private readonly IDomeBlockService _service;

    public DomeBlocksController(IDomeBlockService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<DomeBlockDto>>> List(
        [FromQuery] Guid? domeId, [FromQuery] DateOnly? from, [FromQuery] DateOnly? to, CancellationToken ct = default)
        => Ok(await _service.ListAsync(domeId, from, to, ct));

    [HttpPost]
    public async Task<ActionResult<DomeBlockDto>> Create(CreateDomeBlockDto dto, CancellationToken ct)
    {
        var created = await _service.CreateAsync(dto, ct);
        return CreatedAtAction(nameof(List), new { domeId = created.DomeId }, created);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await _service.DeleteAsync(id, ct);
        return NoContent();
    }
}
