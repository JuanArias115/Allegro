using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Allegro.Domain;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Allegro.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/reservations")]
public class ReservationsController : ControllerBase
{
    private readonly IReservationService _service;

    public ReservationsController(IReservationService service) => _service = service;

    /// <summary>Lista/historial de reservas con filtros opcionales.</summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ReservationSummaryDto>>> List(
        [FromQuery] string? name,
        [FromQuery] string? phone,
        [FromQuery] Guid? domeId,
        [FromQuery] ReservationStatus? status,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] bool? active,
        CancellationToken ct)
    {
        var query = new ReservationQuery(name, phone, domeId, status, from, to, active);
        return Ok(await _service.ListAsync(query, ct));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ReservationDto>> GetById(Guid id, CancellationToken ct)
    {
        var reservation = await _service.GetByIdAsync(id, ct);
        return reservation is null ? NotFound() : Ok(reservation);
    }

    [HttpPost]
    public async Task<ActionResult<ReservationDto>> Create(CreateReservationDto dto, CancellationToken ct)
    {
        var created = await _service.CreateAsync(dto, ct);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ReservationDto>> Update(Guid id, UpdateReservationDto dto, CancellationToken ct)
        => Ok(await _service.UpdateAsync(id, dto, ct));

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult<ReservationDto>> ChangeStatus(Guid id, ChangeStatusDto dto, CancellationToken ct)
        => Ok(await _service.ChangeStatusAsync(id, dto.Status, ct));

    [HttpPost("{id:guid}/payments")]
    public async Task<ActionResult<ReservationDto>> AddPayment(Guid id, CreatePaymentDto dto, CancellationToken ct)
        => Ok(await _service.AddPaymentAsync(id, dto, ct));

    [HttpPost("{id:guid}/consumptions")]
    public async Task<ActionResult<ReservationDto>> AddConsumption(Guid id, CreateConsumptionDto dto, CancellationToken ct)
        => Ok(await _service.AddConsumptionAsync(id, dto, ct));

    [HttpDelete("{id:guid}/consumptions/{consumptionId:guid}")]
    public async Task<ActionResult<ReservationDto>> RemoveConsumption(Guid id, Guid consumptionId, CancellationToken ct)
        => Ok(await _service.RemoveConsumptionAsync(id, consumptionId, ct));

    /// <summary>Resumen de la cuenta para el checkout (no cierra la reserva).</summary>
    [HttpGet("{id:guid}/checkout")]
    public async Task<ActionResult<CheckoutSummaryDto>> GetCheckout(Guid id, CancellationToken ct)
    {
        var summary = await _service.GetCheckoutSummaryAsync(id, ct);
        return summary is null ? NotFound() : Ok(summary);
    }

    /// <summary>Confirma el cierre: registra el pago final opcional y finaliza la reserva.</summary>
    [HttpPost("{id:guid}/checkout")]
    public async Task<ActionResult<ReservationDto>> Checkout(Guid id, [FromBody] CreatePaymentDto? finalPayment, CancellationToken ct)
        => Ok(await _service.CheckoutAsync(id, finalPayment, ct));
}
