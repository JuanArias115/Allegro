using Allegro.Application.Abstractions;
using Allegro.Application.Services;
using Allegro.Domain;
using Allegro.Infrastructure.Persistence;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace Allegro.Tests;

public class FakeClock : IClock
{
    public DateTime UtcNow { get; set; } = new(2026, 6, 19, 12, 0, 0, DateTimeKind.Utc);
    public DateOnly Today { get; set; } = new(2026, 6, 19);
}

/// <summary>
/// Harness de pruebas sobre SQLite en memoria (soporta transacciones reales, a
/// diferencia del proveedor InMemory). La conexión se mantiene abierta para que
/// la base persista entre contextos; cada operación usa un
/// <see cref="AllegroDbContext"/> nuevo, igual que en producción.
/// </summary>
public sealed class TestHarness : IDisposable
{
    public static readonly Guid Dome1 = Guid.Parse("11111111-1111-1111-1111-111111111111");
    public static readonly Guid Dome2 = Guid.Parse("22222222-2222-2222-2222-222222222222");

    public FakeClock Clock { get; } = new();

    private readonly SqliteConnection _connection;
    private readonly AllegroDbContext _db;

    public TestHarness()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AllegroDbContext>()
            .UseSqlite(_connection)
            .Options;
        _db = new AllegroDbContext(options);
        _db.Database.EnsureCreated();

        _db.Domes.AddRange(
            new Dome { Id = Dome1, Name = "Domo 1", ShortDescription = "Test", MaxCapacity = 4, IsActive = true },
            new Dome { Id = Dome2, Name = "Domo 2", ShortDescription = "Test", MaxCapacity = 4, IsActive = true });
        _db.SaveChanges();
    }

    public void Dispose()
    {
        _db.Dispose();
        _connection.Dispose();
    }

    public ReservationService Reservations() => new(_db, Clock);
    public ProductService Products() => new(_db);

    public Product AddProduct(string name, decimal price)
    {
        var p = new Product { Name = name, Category = ProductCategory.Other, CurrentPrice = price, IsActive = true };
        _db.Products.Add(p);
        _db.SaveChanges();
        return p;
    }
}
