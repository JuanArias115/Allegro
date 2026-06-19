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

        services.AddDbContext<AllegroDbContext>(options =>
            options.UseNpgsql(connection, npg => npg.EnableRetryOnFailure()));

        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AllegroDbContext>());
        services.AddSingleton<IClock, SystemClock>();
        services.AddScoped<DataSeeder>();

        return services;
    }
}
