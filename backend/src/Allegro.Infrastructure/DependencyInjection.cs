using Allegro.Application.Abstractions;
using Allegro.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Allegro.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        var connection = config.GetConnectionString("Default")
            ?? throw new InvalidOperationException("Falta la cadena de conexión 'ConnectionStrings:Default'.");

        // Sin estrategia de reintento: usamos transacciones explícitas en las
        // operaciones financieras, incompatibles con el reintento automático.
        services.AddDbContext<AllegroDbContext>(options =>
            options.UseNpgsql(connection));

        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AllegroDbContext>());
        services.AddSingleton<IClock, SystemClock>();
        services.AddScoped<DataSeeder>();

        return services;
    }
}
