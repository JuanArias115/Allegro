using Allegro.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace Allegro.Application.Abstractions;

/// <summary>
/// Abstracción de persistencia usada por la capa de aplicación. La implementación
/// concreta (EF Core + PostgreSQL) vive en la capa de infraestructura.
/// </summary>
public interface IAppDbContext
{
    DbSet<Dome> Domes { get; }
    DbSet<Reservation> Reservations { get; }
    DbSet<Payment> Payments { get; }
    DbSet<Consumption> Consumptions { get; }
    DbSet<Product> Products { get; }
    DbSet<ProductCategory> ProductCategories { get; }

    Task<int> SaveChangesAsync(CancellationToken ct = default);
    Task<IDbContextTransaction> BeginTransactionAsync(CancellationToken ct = default);
}
