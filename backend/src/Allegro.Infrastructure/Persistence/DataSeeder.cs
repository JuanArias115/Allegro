using Allegro.Application.Abstractions;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Allegro.Infrastructure.Persistence;

/// <summary>
/// Siembra datos iniciales seguros. Los dos domos y el catálogo básico se crean
/// si la base está vacía. Las reservas ficticias solo se crean en modo demo
/// (variable SEED_DEMO_DATA) y nunca usan datos reales de clientes.
/// </summary>
public class DataSeeder
{
    private static readonly Guid Dome1Id = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private static readonly Guid Dome2Id = Guid.Parse("22222222-2222-2222-2222-222222222222");

    private readonly AllegroDbContext _db;
    private readonly IClock _clock;
    private readonly ILogger<DataSeeder> _logger;

    public DataSeeder(AllegroDbContext db, IClock clock, ILogger<DataSeeder> logger)
    {
        _db = db;
        _clock = clock;
        _logger = logger;
    }

    public async Task SeedAsync(bool includeDemoReservations, CancellationToken ct = default)
    {
        await SeedDomesAsync(ct);
        await SeedProductsAsync(ct);
        if (includeDemoReservations)
            await SeedDemoReservationsAsync(ct);
    }

    private async Task SeedDomesAsync(CancellationToken ct)
    {
        if (await _db.Domes.AnyAsync(ct)) return;

        _logger.LogInformation("Sembrando domos iniciales.");
        _db.Domes.AddRange(
            new Dome { Id = Dome1Id, Name = "Domo 1", ShortDescription = "Domo con vista al bosque.", MaxCapacity = 2, IsActive = true },
            new Dome { Id = Dome2Id, Name = "Domo 2", ShortDescription = "Domo con jacuzzi privado.", MaxCapacity = 4, IsActive = true });
        await _db.SaveChangesAsync(ct);
    }

    private async Task SeedProductsAsync(CancellationToken ct)
    {
        if (await _db.Products.AnyAsync(ct)) return;

        _logger.LogInformation("Sembrando catálogo de productos.");
        _db.Products.AddRange(
            new Product { Name = "Botella de vino", Category = ProductCategory.Beverages, CurrentPrice = 60000m, IsActive = true },
            new Product { Name = "Cerveza artesanal", Category = ProductCategory.Beverages, CurrentPrice = 12000m, IsActive = true },
            new Product { Name = "Desayuno campestre", Category = ProductCategory.Food, CurrentPrice = 25000m, IsActive = true },
            new Product { Name = "Tabla de quesos", Category = ProductCategory.Food, CurrentPrice = 45000m, IsActive = true },
            new Product { Name = "Decoración romántica", Category = ProductCategory.Services, CurrentPrice = 80000m, IsActive = true },
            new Product { Name = "Late checkout", Category = ProductCategory.Services, CurrentPrice = 50000m, IsActive = true });
        await _db.SaveChangesAsync(ct);
    }

    private async Task SeedDemoReservationsAsync(CancellationToken ct)
    {
        if (await _db.Reservations.AnyAsync(ct)) return;

        _logger.LogInformation("Sembrando reservas de demostración (solo desarrollo).");
        var today = _clock.Today;
        var now = _clock.UtcNow;

        var r1 = new Reservation
        {
            GuestName = "Huésped Demo Uno",
            Phone = "+573000000001",
            DomeId = Dome1Id,
            CheckIn = today,
            CheckOut = today.AddDays(2),
            GuestCount = 2,
            LodgingPrice = 400000m,
            Status = ReservationStatus.CheckedIn,
            Notes = "Reserva de ejemplo (datos ficticios).",
            CreatedAt = now,
            UpdatedAt = now,
            Payments = new List<Payment>
            {
                new() { Amount = 200000m, Method = PaymentMethod.Transfer, PaidAt = now, Note = "Abono inicial" }
            }
        };

        var r2 = new Reservation
        {
            GuestName = "Huésped Demo Dos",
            Phone = "+573000000002",
            DomeId = Dome2Id,
            CheckIn = today.AddDays(3),
            CheckOut = today.AddDays(5),
            GuestCount = 3,
            LodgingPrice = 600000m,
            Status = ReservationStatus.Confirmed,
            Notes = "Reserva de ejemplo (datos ficticios).",
            CreatedAt = now,
            UpdatedAt = now
        };

        var r3 = new Reservation
        {
            GuestName = "Huésped Demo Tres",
            Phone = "+573000000003",
            DomeId = Dome1Id,
            CheckIn = today.AddDays(-10),
            CheckOut = today.AddDays(-8),
            GuestCount = 2,
            LodgingPrice = 380000m,
            Status = ReservationStatus.Completed,
            Notes = "Reserva finalizada de ejemplo.",
            CreatedAt = now,
            UpdatedAt = now,
            Payments = new List<Payment>
            {
                new() { Amount = 380000m, Method = PaymentMethod.Cash, PaidAt = now, Note = "Pago total" }
            }
        };

        _db.Reservations.AddRange(r1, r2, r3);
        await _db.SaveChangesAsync(ct);
    }
}
