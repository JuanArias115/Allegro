using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Allegro.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Allegro.Api.Controllers;

[ApiController]
[Authorize]
[Route("api")]
public class TodayController : ControllerBase
{
    private readonly IReservationService _service;

    public TodayController(IReservationService service) => _service = service;

    /// <summary>Estado del día: llegadas, salidas, ocupados y próximas.</summary>
    [HttpGet("today")]
    public async Task<ActionResult<TodayDto>> GetToday(CancellationToken ct)
        => Ok(await _service.GetTodayAsync(ct));

    /// <summary>Consulta de disponibilidad de un domo para un rango de fechas.</summary>
    [HttpGet("availability")]
    public async Task<ActionResult<AvailabilityDto>> GetAvailability(
        [FromQuery] Guid domeId,
        [FromQuery] DateOnly checkIn,
        [FromQuery] DateOnly checkOut,
        [FromQuery] Guid? excludeReservationId,
        CancellationToken ct)
        => Ok(await _service.CheckAvailabilityAsync(domeId, checkIn, checkOut, excludeReservationId, ct));
}
