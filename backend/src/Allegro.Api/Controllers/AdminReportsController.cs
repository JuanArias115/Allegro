using System.Text;
using Allegro.Api.Auth;
using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Allegro.Api.Controllers;

/// <summary>
/// Reportería administrativa. Los cálculos se hacen en el backend; Angular nunca
/// descarga todas las reservas para calcular. Rango [from, to): inicio inclusivo,
/// fin exclusivo, en zona America/Bogota. Solo administradores.
/// </summary>
[ApiController]
[Authorize(Policy = Policies.Admin)]
[Route("api/admin/reports")]
public class AdminReportsController : ControllerBase
{
    private readonly IReportService _service;

    public AdminReportsController(IReportService service) => _service = service;

    [HttpGet("summary")]
    public async Task<ActionResult<ReportSummaryDto>> Summary([FromQuery] DateOnly from, [FromQuery] DateOnly to, CancellationToken ct)
        => Ok(await _service.GetSummaryAsync(from, to, ct));

    [HttpGet("occupancy")]
    public async Task<ActionResult<OccupancyReportDto>> Occupancy([FromQuery] DateOnly from, [FromQuery] DateOnly to, CancellationToken ct)
        => Ok(await _service.GetOccupancyAsync(from, to, ct));

    [HttpGet("payments")]
    public async Task<ActionResult<PaymentsReportDto>> Payments([FromQuery] DateOnly from, [FromQuery] DateOnly to, CancellationToken ct)
        => Ok(await _service.GetPaymentsAsync(from, to, ct));

    [HttpGet("products")]
    public async Task<ActionResult<ProductsReportDto>> Products([FromQuery] DateOnly from, [FromQuery] DateOnly to, CancellationToken ct)
        => Ok(await _service.GetProductsAsync(from, to, ct));

    /// <summary>Exporta el resumen + ocupación + ventas de productos del periodo en CSV.</summary>
    [HttpGet("export.csv")]
    public async Task<IActionResult> ExportCsv([FromQuery] DateOnly from, [FromQuery] DateOnly to, CancellationToken ct)
    {
        var summary = await _service.GetSummaryAsync(from, to, ct);
        var occupancy = await _service.GetOccupancyAsync(from, to, ct);
        var products = await _service.GetProductsAsync(from, to, ct);

        var csv = ReportCsv.Build(summary, occupancy, products);
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv)).ToArray();
        return File(bytes, "text/csv", $"reporte_{summary.From:yyyyMMdd}_{summary.To:yyyyMMdd}.csv");
    }
}
