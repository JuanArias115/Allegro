using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Allegro.Infrastructure.Persistence;

/// <summary>
/// Fábrica usada solo en tiempo de diseño por `dotnet ef` para generar migraciones.
/// La cadena de conexión real se inyecta en ejecución desde la API.
/// </summary>
public class AllegroDbContextFactory : IDesignTimeDbContextFactory<AllegroDbContext>
{
    public AllegroDbContext CreateDbContext(string[] args)
    {
        var connection = Environment.GetEnvironmentVariable("ConnectionStrings__Default")
            ?? "Host=localhost;Port=5432;Database=allegro;Username=allegro;Password=allegro";

        var options = new DbContextOptionsBuilder<AllegroDbContext>()
            .UseNpgsql(connection)
            .Options;

        return new AllegroDbContext(options);
    }
}
