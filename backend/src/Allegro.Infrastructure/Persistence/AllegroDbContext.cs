using Allegro.Application.Abstractions;
using Allegro.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace Allegro.Infrastructure.Persistence;

public class AllegroDbContext : DbContext, IAppDbContext
{
    public AllegroDbContext(DbContextOptions<AllegroDbContext> options) : base(options) { }

    public DbSet<Dome> Domes => Set<Dome>();
    public DbSet<Reservation> Reservations => Set<Reservation>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Consumption> Consumptions => Set<Consumption>();
    public DbSet<Product> Products => Set<Product>();

    public Task<IDbContextTransaction> BeginTransactionAsync(CancellationToken ct = default) =>
        Database.BeginTransactionAsync(ct);

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);

        b.Entity<Dome>(e =>
        {
            e.ToTable("domes");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(80);
            e.Property(x => x.ShortDescription).HasMaxLength(280);
            e.Property(x => x.IsActive).HasDefaultValue(true);
        });

        b.Entity<Product>(e =>
        {
            e.ToTable("products");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(120);
            e.Property(x => x.Category).HasConversion<int>();
            e.Property(x => x.CurrentPrice).HasColumnType("numeric(12,2)");
            e.Property(x => x.IsActive).HasDefaultValue(true);
            e.Property(x => x.ImageUrl).HasMaxLength(500);
            e.HasIndex(x => x.Category);
        });

        b.Entity<Reservation>(e =>
        {
            e.ToTable("reservations");
            e.HasKey(x => x.Id);
            e.Property(x => x.GuestName).IsRequired().HasMaxLength(120);
            e.Property(x => x.Phone).IsRequired().HasMaxLength(40);
            e.Property(x => x.CheckIn).HasColumnType("date");
            e.Property(x => x.CheckOut).HasColumnType("date");
            e.Property(x => x.LodgingPrice).HasColumnType("numeric(12,2)");
            e.Property(x => x.Status).HasConversion<int>();
            e.Property(x => x.Notes).HasMaxLength(1000);
            e.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone");
            e.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");

            // Cálculos: no se persisten.
            e.Ignore(x => x.TotalPaid);
            e.Ignore(x => x.TotalConsumptions);
            e.Ignore(x => x.TotalDue);
            e.Ignore(x => x.Balance);
            e.Ignore(x => x.BlocksAvailability);

            e.HasOne(x => x.Dome)
                .WithMany(d => d.Reservations)
                .HasForeignKey(x => x.DomeId)
                .OnDelete(DeleteBehavior.Restrict);

            // Índices útiles para disponibilidad e historial.
            e.HasIndex(x => new { x.DomeId, x.CheckIn, x.CheckOut });
            e.HasIndex(x => x.Status);
            e.HasIndex(x => x.GuestName);
            e.HasIndex(x => x.Phone);
        });

        b.Entity<Payment>(e =>
        {
            e.ToTable("payments");
            e.HasKey(x => x.Id);
            e.Property(x => x.Amount).HasColumnType("numeric(12,2)");
            e.Property(x => x.Method).HasConversion<int>();
            e.Property(x => x.Note).HasMaxLength(500);
            e.Property(x => x.PaidAt).HasColumnType("timestamp with time zone");

            e.HasOne(x => x.Reservation)
                .WithMany(r => r.Payments)
                .HasForeignKey(x => x.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasIndex(x => x.ReservationId);
        });

        b.Entity<Consumption>(e =>
        {
            e.ToTable("consumptions");
            e.HasKey(x => x.Id);
            e.Property(x => x.ProductName).IsRequired().HasMaxLength(120);
            e.Property(x => x.UnitPrice).HasColumnType("numeric(12,2)");
            e.Property(x => x.ConsumedAt).HasColumnType("timestamp with time zone");
            e.Ignore(x => x.Subtotal);

            e.HasOne(x => x.Reservation)
                .WithMany(r => r.Consumptions)
                .HasForeignKey(x => x.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.Product)
                .WithMany()
                .HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(x => x.ReservationId);
            e.HasIndex(x => x.ProductId);
        });
    }
}
