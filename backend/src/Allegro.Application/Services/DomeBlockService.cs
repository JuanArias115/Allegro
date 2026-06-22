using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Application.Services;

public interface IDomeBlockService
{
    Task<IReadOnlyList<DomeBlockDto>> ListAsync(Guid? domeId, DateOnly? from, DateOnly? to, CancellationToken ct = default);
    Task<DomeBlockDto> CreateAsync(CreateDomeBlockDto dto, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
}

public class DomeBlockService : IDomeBlockService
{
    private readonly IAppDbContext _db;
    private readonly IClock _clock;

    public DomeBlockService(IAppDbContext db, IClock clock)
    {
        _db = db;
        _clock = clock;
    }

    public async Task<IReadOnlyList<DomeBlockDto>> ListAsync(Guid? domeId, DateOnly? from, DateOnly? to, CancellationToken ct = default)
    {
        var q = _db.DomeBlocks.AsNoTracking().Include(b => b.Dome).AsQueryable();
        if (domeId is { } id) q = q.Where(b => b.DomeId == id);
        if (from is { } f) q = q.Where(b => b.EndDate > f);
        if (to is { } t) q = q.Where(b => b.StartDate < t);

        var list = await q.OrderBy(b => b.StartDate).ToListAsync(ct);
        return list.Select(ToDto).ToList();
    }

    public async Task<DomeBlockDto> CreateAsync(CreateDomeBlockDto dto, CancellationToken ct = default)
    {
        var dome = await _db.Domes.FirstOrDefaultAsync(d => d.Id == dto.DomeId, ct)
            ?? throw new DomainException("El domo seleccionado no existe.");
        if (dto.EndDate <= dto.StartDate)
            throw new DomainException("La fecha final debe ser posterior a la inicial.");

        // No se puede bloquear sobre reservas activas existentes.
        var reservationConflict = await _db.Reservations.AsNoTracking()
            .AnyAsync(r => r.DomeId == dto.DomeId
                           && r.Status != ReservationStatus.Cancelled
                           && r.CheckIn < dto.EndDate
                           && dto.StartDate < r.CheckOut, ct);
        if (reservationConflict)
            throw new DomainException("Hay una reserva activa que se cruza con esas fechas.");

        // Ni sobre otro bloqueo del mismo domo.
        var blockConflict = await _db.DomeBlocks.AsNoTracking()
            .AnyAsync(b => b.DomeId == dto.DomeId
                           && b.StartDate < dto.EndDate
                           && dto.StartDate < b.EndDate, ct);
        if (blockConflict)
            throw new DomainException("Ya existe un bloqueo que se cruza con esas fechas.");

        var block = new DomeBlock
        {
            DomeId = dto.DomeId,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            Reason = dto.Reason.Trim(),
            CreatedAt = _clock.UtcNow,
        };
        _db.DomeBlocks.Add(block);
        await _db.SaveChangesAsync(ct);
        block.Dome = dome;
        return ToDto(block);
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var block = await _db.DomeBlocks.FirstOrDefaultAsync(b => b.Id == id, ct)
            ?? throw new DomainException("El bloqueo no existe.");
        _db.DomeBlocks.Remove(block);
        await _db.SaveChangesAsync(ct);
    }

    private static DomeBlockDto ToDto(DomeBlock b) =>
        new(b.Id, b.DomeId, b.Dome?.Name ?? "", b.StartDate, b.EndDate, b.Reason, b.CreatedAt);
}
