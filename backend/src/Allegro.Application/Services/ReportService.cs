using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Application.Services;

public interface IReportService
{
    Task<ReportSummaryDto> GetSummaryAsync(DateOnly from, DateOnly to, CancellationToken ct = default);
    Task<OccupancyReportDto> GetOccupancyAsync(DateOnly from, DateOnly to, CancellationToken ct = default);
    Task<PaymentsReportDto> GetPaymentsAsync(DateOnly from, DateOnly to, CancellationToken ct = default);
    Task<ProductsReportDto> GetProductsAsync(DateOnly from, DateOnly to, CancellationToken ct = default);
}

/// <summary>
/// Cálculos de reportería en el backend. Rango [from, to): inicio inclusivo, fin
/// exclusivo. Montos en <c>decimal</c>. Fechas de pagos/consumos se interpretan en
/// la zona del negocio (America/Bogota) vía <see cref="IClock.ToBusinessDate"/>.
/// </summary>
public class ReportService : IReportService
{
    private readonly IAppDbContext _db;
    private readonly IClock _clock;

    public ReportService(IAppDbContext db, IClock clock)
    {
        _db = db;
        _clock = clock;
    }

    public async Task<ReportSummaryDto> GetSummaryAsync(DateOnly from, DateOnly to, CancellationToken ct = default)
    {
        EnsureRange(from, to);
        var rangeNights = to.DayNumber - from.DayNumber;

        var reservations = await LoadOverlappingReservationsAsync(from, to, ct);
        var activeDomeIds = await _db.Domes.AsNoTracking()
            .Where(d => d.IsActive)
            .Select(d => d.Id)
            .ToListAsync(ct);
        var blocks = await LoadOverlappingBlocksAsync(from, to, ct);

        var nonCancelled = reservations.Where(r => r.Status != ReservationStatus.Cancelled).ToList();

        // Reservas atribuidas al periodo por su llegada (una sola vez).
        var byCheckIn = nonCancelled.Where(r => r.CheckIn >= from && r.CheckIn < to).ToList();
        var cancellations = reservations.Count(r =>
            r.Status == ReservationStatus.Cancelled && r.CheckIn >= from && r.CheckIn < to);

        var reservedValue = byCheckIn.Sum(r => r.LodgingPrice);
        var nightsReserved = byCheckIn.Sum(r => r.CheckOut.DayNumber - r.CheckIn.DayNumber);
        var pendingBalance = byCheckIn.Sum(r => r.Balance);

        // Ocupación: noches de solapamiento (sin doble conteo entre meses).
        var occupiedNights = nonCancelled.Sum(r => OverlapNights(r.CheckIn, r.CheckOut, from, to));
        var blockedNights = blocks
            .Where(b => activeDomeIds.Contains(b.DomeId))
            .Sum(b => OverlapNights(b.StartDate, b.EndDate, from, to));
        var availableNights = Math.Max(0, activeDomeIds.Count * rangeNights - blockedNights);
        var occupancyRate = Rate(occupiedNights, availableNights);

        var paymentsReceived = await SumPaymentsAsync(from, to, ct);
        var productSalesValue = (await ProductSalesAsync(from, to, ct)).Sum(i => i.Value);

        return new ReportSummaryDto(
            from, to,
            ReservationsCount: byCheckIn.Count,
            Cancellations: cancellations,
            NightsReserved: nightsReserved,
            OccupiedNights: occupiedNights,
            AvailableNights: availableNights,
            OccupancyRate: occupancyRate,
            ReservedValue: reservedValue,
            PaymentsReceived: paymentsReceived,
            PendingBalance: pendingBalance,
            ProductSalesValue: productSalesValue);
    }

    public async Task<OccupancyReportDto> GetOccupancyAsync(DateOnly from, DateOnly to, CancellationToken ct = default)
    {
        EnsureRange(from, to);
        var rangeNights = to.DayNumber - from.DayNumber;

        var domes = await _db.Domes.AsNoTracking()
            .Where(d => d.IsActive)
            .OrderBy(d => d.Name)
            .ToListAsync(ct);
        var reservations = await LoadOverlappingReservationsAsync(from, to, ct);
        var active = reservations.Where(r => r.Status != ReservationStatus.Cancelled).ToList();
        var blocks = await LoadOverlappingBlocksAsync(from, to, ct);

        var perDome = domes.Select(d =>
        {
            var occupied = active.Where(r => r.DomeId == d.Id)
                .Sum(r => OverlapNights(r.CheckIn, r.CheckOut, from, to));
            var blocked = blocks.Where(b => b.DomeId == d.Id)
                .Sum(b => OverlapNights(b.StartDate, b.EndDate, from, to));
            var available = Math.Max(0, rangeNights - blocked);
            return new OccupancyByDomeDto(d.Id, d.Name, occupied, available, Rate(occupied, available));
        }).ToList();

        var totalOccupied = perDome.Sum(d => d.OccupiedNights);
        var totalAvailable = perDome.Sum(d => d.AvailableNights);

        return new OccupancyReportDto(from, to, totalOccupied, totalAvailable, Rate(totalOccupied, totalAvailable), perDome);
    }

    public async Task<PaymentsReportDto> GetPaymentsAsync(DateOnly from, DateOnly to, CancellationToken ct = default)
    {
        EnsureRange(from, to);

        // Pagos válidos independientemente del estado posterior de la reserva.
        var payments = await _db.Payments.AsNoTracking().ToListAsync(ct);
        var inRange = payments
            .Select(p => new { Date = _clock.ToBusinessDate(p.PaidAt), p.Amount })
            .Where(x => x.Date >= from && x.Date < to)
            .ToList();

        var byDay = inRange
            .GroupBy(x => x.Date)
            .OrderBy(g => g.Key)
            .Select(g => new PaymentBucketDto(g.Key, g.Sum(x => x.Amount)))
            .ToList();

        return new PaymentsReportDto(from, to, inRange.Sum(x => x.Amount), byDay);
    }

    public async Task<ProductsReportDto> GetProductsAsync(DateOnly from, DateOnly to, CancellationToken ct = default)
    {
        EnsureRange(from, to);
        var items = await ProductSalesAsync(from, to, ct);
        return new ProductsReportDto(
            from, to,
            TotalQuantity: items.Sum(i => i.Quantity),
            TotalValue: items.Sum(i => i.Value),
            Items: items);
    }

    // ---------- helpers ----------

    private async Task<List<Reservation>> LoadOverlappingReservationsAsync(DateOnly from, DateOnly to, CancellationToken ct)
    {
        // Reservas que solapan el rango O cuya llegada cae en el rango.
        return await _db.Reservations.AsNoTracking()
            .Include(r => r.Payments)
            .Include(r => r.Consumptions)
            .Where(r => r.CheckIn < to && from < r.CheckOut)
            .ToListAsync(ct);
    }

    private Task<List<DomeBlock>> LoadOverlappingBlocksAsync(DateOnly from, DateOnly to, CancellationToken ct) =>
        _db.DomeBlocks.AsNoTracking()
            .Where(b => b.StartDate < to && from < b.EndDate)
            .ToListAsync(ct);

    private async Task<decimal> SumPaymentsAsync(DateOnly from, DateOnly to, CancellationToken ct)
    {
        var payments = await _db.Payments.AsNoTracking().Select(p => new { p.PaidAt, p.Amount }).ToListAsync(ct);
        return payments
            .Where(p => { var d = _clock.ToBusinessDate(p.PaidAt); return d >= from && d < to; })
            .Sum(p => p.Amount);
    }

    private async Task<List<ProductSalesDto>> ProductSalesAsync(DateOnly from, DateOnly to, CancellationToken ct)
    {
        var consumptions = await _db.Consumptions.AsNoTracking()
            .Select(c => new { c.ProductId, c.ProductName, c.Quantity, c.UnitPrice, c.ConsumedAt })
            .ToListAsync(ct);

        return consumptions
            .Where(c => { var d = _clock.ToBusinessDate(c.ConsumedAt); return d >= from && d < to; })
            .GroupBy(c => new { c.ProductId, c.ProductName })
            .Select(g => new ProductSalesDto(
                g.Key.ProductId,
                g.Key.ProductName,
                g.Sum(x => x.Quantity),
                g.Sum(x => x.Quantity * x.UnitPrice)))
            .OrderByDescending(i => i.Value)
            .ToList();
    }

    /// <summary>Noches de solapamiento entre [aStart,aEnd) y [bStart,bEnd).</summary>
    private static int OverlapNights(DateOnly aStart, DateOnly aEnd, DateOnly bStart, DateOnly bEnd)
    {
        var start = aStart > bStart ? aStart : bStart;
        var end = aEnd < bEnd ? aEnd : bEnd;
        var nights = end.DayNumber - start.DayNumber;
        return nights > 0 ? nights : 0;
    }

    private static decimal Rate(int occupied, int available) =>
        available <= 0 ? 0m : Math.Round((decimal)occupied / available, 4);

    private static void EnsureRange(DateOnly from, DateOnly to)
    {
        if (to <= from)
            throw new DomainException("El rango de fechas no es válido: la fecha final debe ser posterior a la inicial.");
    }
}
