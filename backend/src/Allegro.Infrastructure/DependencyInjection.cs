using Allegro.Application.Abstractions;
using Allegro.Infrastructure.Firebase;
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

        // Gestión de usuarios: implementación real solo con AUTH_MODE=firebase
        // (requiere credenciales de Firebase Admin). En otros modos, un stub seguro.
        var mode = (config["AUTH_MODE"] ?? "local").Trim().ToLowerInvariant();
        if (mode == "firebase")
        {
            FirebaseAppInitializer.EnsureInitialized(config["FIREBASE_PROJECT_ID"]);
            services.AddSingleton<IFirebaseUserManagementService, FirebaseUserManagementService>();
        }
        else
        {
            services.AddSingleton<IFirebaseUserManagementService, UnavailableFirebaseUserManagementService>();
        }

        return services;
    }
}
