using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Application.Services;

/// <summary>Filtros para el historial / listado de reservas.</summary>
public record ReservationQuery(
    string? Name = null,
    string? Phone = null,
    Guid? DomeId = null,
    ReservationStatus? Status = null,
    DateOnly? From = null,
    DateOnly? To = null,
    bool? Active = null);

public interface IReservationService
{
    Task<IReadOnlyList<ReservationSummaryDto>> ListAsync(ReservationQuery query, CancellationToken ct = default);
    Task<ReservationDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<ReservationDto> CreateAsync(CreateReservationDto dto, CancellationToken ct = default);
    Task<ReservationDto> UpdateAsync(Guid id, UpdateReservationDto dto, CancellationToken ct = default);
    Task<ReservationDto> ChangeStatusAsync(Guid id, ReservationStatus status, CancellationToken ct = default);
    Task<ReservationDto> AddPaymentAsync(Guid id, CreatePaymentDto dto, CancellationToken ct = default);
    Task<ReservationDto> AddConsumptionAsync(Guid id, CreateConsumptionDto dto, CancellationToken ct = default);
    Task<ReservationDto> RemoveConsumptionAsync(Guid id, Guid consumptionId, CancellationToken ct = default);
    Task<CheckoutSummaryDto?> GetCheckoutSummaryAsync(Guid id, CancellationToken ct = default);
    Task<ReservationDto> CheckoutAsync(Guid id, CreatePaymentDto? finalPayment, CancellationToken ct = default);
    Task<AvailabilityDto> CheckAvailabilityAsync(Guid domeId, DateOnly checkIn, DateOnly checkOut, Guid? excludeReservationId, CancellationToken ct = default);
    Task<TodayDto> GetTodayAsync(CancellationToken ct = default);
}

public class ReservationService : IReservationService
{
    private readonly IAppDbContext _db;
    private readonly IClock _clock;

    public ReservationService(IAppDbContext db, IClock clock)
    {
        _db = db;
        _clock = clock;
    }

    public async Task<IReadOnlyList<ReservationSummaryDto>> ListAsync(ReservationQuery query, CancellationToken ct = default)
    {
        var q = _db.Reservations.AsNoTracking()
            .Include(r => r.Dome)
            .Include(r => r.Payments)
            .Include(r => r.Consumptions)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Name))
        {
            var name = query.Name.Trim().ToLower();
            q = q.Where(r => r.GuestName.ToLower().Contains(name));
        }
        if (!string.IsNullOrWhiteSpace(query.Phone))
            q = q.Where(r => r.Phone.Contains(query.Phone.Trim()));
        if (query.DomeId is { } domeId)
            q = q.Where(r => r.DomeId == domeId);
        if (query.Status is { } status)
            q = q.Where(r => r.Status == status);
        if (query.From is { } from)
            q = q.Where(r => r.CheckOut > from);
        if (query.To is { } to)
            q = q.Where(r => r.CheckIn < to);

        if (query.Active == true)
            q = q.Where(r => r.Status == ReservationStatus.Confirmed || r.Status == ReservationStatus.CheckedIn);
        else if (query.Active == false)
            q = q.Where(r => r.Status == ReservationStatus.Completed || r.Status == ReservationStatus.Cancelled);

        var list = await q.OrderBy(r => r.CheckIn).ThenBy(r => r.GuestName).ToListAsync(ct);
        return list.Select(r => r.ToSummary()).ToList();
    }

    public async Task<ReservationDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var reservation = await LoadFullAsync(id, tracking: false, ct);
        return reservation?.ToDto();
    }

    public async Task<ReservationDto> CreateAsync(CreateReservationDto dto, CancellationToken ct = default)
    {
        var dome = await _db.Domes.FirstOrDefaultAsync(d => d.Id == dto.DomeId, ct)
            ?? throw new DomainException("El domo seleccionado no existe.");
        if (!dome.IsActive)
            throw new DomainException("El domo seleccionado está inactivo.");

        EnsureValidDates(dto.CheckIn, dto.CheckOut);
        EnsureCapacity(dome, dto.GuestCount);
        await EnsureNoOverlapAsync(dto.DomeId, dto.CheckIn, dto.CheckOut, excludeReservationId: null, ct);

        var now = _clock.UtcNow;
        var reservation = new Reservation
        {
            GuestName = dto.GuestName.Trim(),
            Phone = dto.Phone.Trim(),
            DomeId = dto.DomeId,
            CheckIn = dto.CheckIn,
            CheckOut = dto.CheckOut,
            GuestCount = dto.GuestCount,
            LodgingPrice = dto.LodgingPrice,
            Notes = string.IsNullOrWhiteSpace(dto.Notes) ? null : dto.Notes.Trim(),
            Status = ReservationStatus.Confirmed,
            CreatedAt = now,
            UpdatedAt = now
        };

        _db.Reservations.Add(reservation);
        await _db.SaveChangesAsync(ct);

        return (await LoadFullAsync(reservation.Id, tracking: false, ct))!.ToDto();
    }

    public async Task<ReservationDto> UpdateAsync(Guid id, UpdateReservationDto dto, CancellationToken ct = default)
    {
        var reservation = await LoadFullAsync(id, tracking: true, ct)
            ?? throw new DomainException("La reserva no existe.");

        if (reservation.Status == ReservationStatus.Completed || reservation.Status == ReservationStatus.Cancelled)
            throw new DomainException("No se puede editar una reserva finalizada o cancelada.");

        var dome = await _db.Domes.FirstOrDefaultAsync(d => d.Id == dto.DomeId, ct)
            ?? throw new DomainException("El domo seleccionado no existe.");

        EnsureValidDates(dto.CheckIn, dto.CheckOut);
        EnsureCapacity(dome, dto.GuestCount);
        await EnsureNoOverlapAsync(dto.DomeId, dto.CheckIn, dto.CheckOut, excludeReservationId: id, ct);

        reservation.GuestName = dto.GuestName.Trim();
        reservation.Phone = dto.Phone.Trim();
        reservation.DomeId = dto.DomeId;
        reservation.CheckIn = dto.CheckIn;
        reservation.CheckOut = dto.CheckOut;
        reservation.GuestCount = dto.GuestCount;
        reservation.LodgingPrice = dto.LodgingPrice;
        reservation.Notes = string.IsNullOrWhiteSpace(dto.Notes) ? null : dto.Notes.Trim();
        reservation.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(ct);
        return (await LoadFullAsync(id, tracking: false, ct))!.ToDto();
    }

    public async Task<ReservationDto> ChangeStatusAsync(Guid id, ReservationStatus status, CancellationToken ct = default)
    {
        var reservation = await LoadFullAsync(id, tracking: true, ct)
            ?? throw new DomainException("La reserva no existe.");

        reservation.Status = status;
        reservation.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(ct);
        return (await LoadFullAsync(id, tracking: false, ct))!.ToDto();
    }

    public async Task<ReservationDto> AddPaymentAsync(Guid id, CreatePaymentDto dto, CancellationToken ct = default)
    {
        await using var tx = await _db.BeginTransactionAsync(ct);

        var reservation = await LoadFullAsync(id, tracking: true, ct)
            ?? throw new DomainException("La reserva no existe.");
        if (reservation.Status == ReservationStatus.Cancelled)
            throw new DomainException("No se pueden registrar abonos en una reserva cancelada.");
        if (dto.Amount <= 0)
            throw new DomainException("El valor del abono debe ser mayor que cero.");

        _db.Payments.Add(new Payment
        {
            ReservationId = reservation.Id,
            Amount = dto.Amount,
            Method = dto.Method,
            Note = string.IsNullOrWhiteSpace(dto.Note) ? null : dto.Note.Trim(),
            PaidAt = NormalizeUtc(dto.PaidAt) ?? _clock.UtcNow
        });
        reservation.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return (await LoadFullAsync(id, tracking: false, ct))!.ToDto();
    }

    public async Task<ReservationDto> AddConsumptionAsync(Guid id, CreateConsumptionDto dto, CancellationToken ct = default)
    {
        await using var tx = await _db.BeginTransactionAsync(ct);

        var reservation = await LoadFullAsync(id, tracking: true, ct)
            ?? throw new DomainException("La reserva no existe.");
        if (reservation.Status == ReservationStatus.Cancelled)
            throw new DomainException("No se pueden registrar consumos en una reserva cancelada.");
        if (dto.Quantity <= 0)
            throw new DomainException("La cantidad debe ser mayor que cero.");

        var product = await _db.Products.FirstOrDefaultAsync(p => p.Id == dto.ProductId, ct)
            ?? throw new DomainException("El producto no existe.");

        // El precio y el nombre se congelan en el momento del consumo.
        _db.Consumptions.Add(new Consumption
        {
            ReservationId = reservation.Id,
            ProductId = product.Id,
            ProductName = product.Name,
            Quantity = dto.Quantity,
            UnitPrice = product.CurrentPrice,
            ConsumedAt = NormalizeUtc(dto.ConsumedAt) ?? _clock.UtcNow
        });
        reservation.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return (await LoadFullAsync(id, tracking: false, ct))!.ToDto();
    }

    public async Task<ReservationDto> RemoveConsumptionAsync(Guid id, Guid consumptionId, CancellationToken ct = default)
    {
        await using var tx = await _db.BeginTransactionAsync(ct);

        var reservation = await LoadFullAsync(id, tracking: true, ct)
            ?? throw new DomainException("La reserva no existe.");
        var consumption = reservation.Consumptions.FirstOrDefault(c => c.Id == consumptionId)
            ?? throw new DomainException("El consumo no existe en esta reserva.");

        _db.Consumptions.Remove(consumption);
        reservation.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return (await LoadFullAsync(id, tracking: false, ct))!.ToDto();
    }

    public async Task<CheckoutSummaryDto?> GetCheckoutSummaryAsync(Guid id, CancellationToken ct = default)
    {
        var reservation = await LoadFullAsync(id, tracking: false, ct);
        return reservation?.ToCheckoutSummary();
    }

    public async Task<ReservationDto> CheckoutAsync(Guid id, CreatePaymentDto? finalPayment, CancellationToken ct = default)
    {
        await using var tx = await _db.BeginTransactionAsync(ct);

        var reservation = await LoadFullAsync(id, tracking: true, ct)
            ?? throw new DomainException("La reserva no existe.");
        if (reservation.Status == ReservationStatus.Cancelled)
            throw new DomainException("No se puede hacer checkout de una reserva cancelada.");

        if (finalPayment is { Amount: > 0 })
        {
            _db.Payments.Add(new Payment
            {
                ReservationId = reservation.Id,
                Amount = finalPayment.Amount,
                Method = finalPayment.Method,
                Note = string.IsNullOrWhiteSpace(finalPayment.Note) ? "Pago final de checkout" : finalPayment.Note.Trim(),
                PaidAt = NormalizeUtc(finalPayment.PaidAt) ?? _clock.UtcNow
            });
        }

        // El cierre se confirma explícitamente: marcamos la reserva como finalizada.
        reservation.Status = ReservationStatus.Completed;
        reservation.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return (await LoadFullAsync(id, tracking: false, ct))!.ToDto();
    }

    public async Task<AvailabilityDto> CheckAvailabilityAsync(Guid domeId, DateOnly checkIn, DateOnly checkOut, Guid? excludeReservationId, CancellationToken ct = default)
    {
        EnsureValidDates(checkIn, checkOut);
        var conflicts = await FindOverlapsAsync(domeId, checkIn, checkOut, excludeReservationId, ct);
        return new AvailabilityDto(
            domeId, checkIn, checkOut,
            IsAvailable: conflicts.Count == 0,
            Conflicts: conflicts.Select(r => r.ToSummary()).ToList());
    }

    public async Task<TodayDto> GetTodayAsync(CancellationToken ct = default)
    {
        var today = _clock.Today;

        var relevant = await _db.Reservations.AsNoTracking()
            .Include(r => r.Dome)
            .Include(r => r.Payments)
            .Include(r => r.Consumptions)
            .Where(r => r.Status != ReservationStatus.Cancelled)
            .ToListAsync(ct);

        var arrivals = relevant
            .Where(r => r.CheckIn == today && r.Status != ReservationStatus.Completed)
            .OrderBy(r => r.GuestName).Select(r => r.ToSummary()).ToList();

        var departures = relevant
            .Where(r => r.CheckOut == today && r.Status != ReservationStatus.Completed)
            .OrderBy(r => r.GuestName).Select(r => r.ToSummary()).ToList();

        var hosted = relevant
            .Where(r => r.CheckIn <= today && today < r.CheckOut
                        && (r.Status == ReservationStatus.CheckedIn || r.Status == ReservationStatus.Confirmed))
            .OrderBy(r => r.Dome!.Name).Select(r => r.ToSummary()).ToList();

        var upcoming = relevant
            .Where(r => r.CheckIn > today && r.Status == ReservationStatus.Confirmed)
            .OrderBy(r => r.CheckIn).Take(10).Select(r => r.ToSummary()).ToList();

        return new TodayDto(today, arrivals, departures, hosted, upcoming);
    }

    // ----------------- helpers -----------------

    private async Task<Reservation?> LoadFullAsync(Guid id, bool tracking, CancellationToken ct)
    {
        var q = _db.Reservations
            .Include(r => r.Dome)
            .Include(r => r.Payments)
            .Include(r => r.Consumptions)
            .AsQueryable();
        if (!tracking) q = q.AsNoTracking();
        return await q.FirstOrDefaultAsync(r => r.Id == id, ct);
    }

    private async Task<List<Reservation>> FindOverlapsAsync(Guid domeId, DateOnly checkIn, DateOnly checkOut, Guid? excludeId, CancellationToken ct)
    {
        return await _db.Reservations.AsNoTracking()
            .Include(r => r.Dome)
            .Include(r => r.Payments)
            .Include(r => r.Consumptions)
            .Where(r => r.DomeId == domeId
                        && r.Status != ReservationStatus.Cancelled
                        && (excludeId == null || r.Id != excludeId)
                        && r.CheckIn < checkOut
                        && checkIn < r.CheckOut)
            .ToListAsync(ct);
    }

    private async Task EnsureNoOverlapAsync(Guid domeId, DateOnly checkIn, DateOnly checkOut, Guid? excludeReservationId, CancellationToken ct)
    {
        var overlaps = await FindOverlapsAsync(domeId, checkIn, checkOut, excludeReservationId, ct);
        if (overlaps.Count > 0)
            throw new DomainException("El domo ya tiene una reserva activa que se cruza con esas fechas.");
    }

    private static void EnsureValidDates(DateOnly checkIn, DateOnly checkOut)
    {
        if (checkOut <= checkIn)
            throw new DomainException("La fecha de salida debe ser posterior a la fecha de llegada.");
    }

    private static void EnsureCapacity(Dome dome, int guestCount)
    {
        if (guestCount > dome.MaxCapacity)
            throw new DomainException($"El domo admite máximo {dome.MaxCapacity} huéspedes.");
    }

    private static DateTime? NormalizeUtc(DateTime? value)
    {
        if (value is null) return null;
        var v = value.Value;
        return v.Kind switch
        {
            DateTimeKind.Utc => v,
            DateTimeKind.Local => v.ToUniversalTime(),
            _ => DateTime.SpecifyKind(v, DateTimeKind.Utc)
        };
    }
}
