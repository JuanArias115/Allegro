using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Allegro.Api.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Allegro.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/domes")]
public class DomesController : ControllerBase
{
    private readonly IDomeService _service;

    public DomesController(IDomeService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<DomeDto>>> GetAll([FromQuery] bool onlyActive = false, CancellationToken ct = default)
        => Ok(await _service.GetAllAsync(onlyActive, ct));

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DomeDto>> GetById(Guid id, CancellationToken ct)
    {
        var dome = await _service.GetByIdAsync(id, ct);
        return dome is null ? NotFound() : Ok(dome);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = Policies.Admin)]
    public async Task<ActionResult<DomeDto>> Update(Guid id, UpsertDomeDto dto, CancellationToken ct)
        => Ok(await _service.UpdateAsync(id, dto, ct));
}
