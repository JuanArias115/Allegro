using Allegro.Application.Abstractions;
using Allegro.Application.Dtos;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Application.Services;

public interface IDomeService
{
    Task<IReadOnlyList<DomeDto>> GetAllAsync(bool onlyActive, CancellationToken ct = default);
    Task<DomeDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<DomeDto> UpdateAsync(Guid id, UpsertDomeDto dto, CancellationToken ct = default);
}

public class DomeService : IDomeService
{
    private readonly IAppDbContext _db;

    public DomeService(IAppDbContext db) => _db = db;

    public async Task<IReadOnlyList<DomeDto>> GetAllAsync(bool onlyActive, CancellationToken ct = default)
    {
        var query = _db.Domes.AsNoTracking().OrderBy(d => d.Name).AsQueryable();
        if (onlyActive) query = query.Where(d => d.IsActive);
        var list = await query.ToListAsync(ct);
        return list.Select(d => d.ToDto()).ToList();
    }

    public async Task<DomeDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var dome = await _db.Domes.AsNoTracking().FirstOrDefaultAsync(d => d.Id == id, ct);
        return dome?.ToDto();
    }

    public async Task<DomeDto> UpdateAsync(Guid id, UpsertDomeDto dto, CancellationToken ct = default)
    {
        var dome = await _db.Domes.FirstOrDefaultAsync(d => d.Id == id, ct)
            ?? throw new DomainException("El domo no existe.");

        dome.Name = dto.Name.Trim();
        dome.ShortDescription = dto.ShortDescription.Trim();
        dome.MaxCapacity = dto.MaxCapacity;
        dome.IsActive = dto.IsActive;

        await _db.SaveChangesAsync(ct);
        return dome.ToDto();
    }
}
