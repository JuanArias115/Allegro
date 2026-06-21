using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using Allegro.Api.Auth;
using Allegro.Api.HealthChecks;
using Allegro.Api.Middleware;
using Allegro.Application;
using Allegro.Infrastructure;
using Allegro.Infrastructure.Persistence;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidationFilter>();
})
.AddJsonOptions(o =>
{
    o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Allegro API", Version = "v1", Description = "API interna para administrar el glamping." });
    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Token de Firebase (o token de desarrollo en modo local).",
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
    };
    c.AddSecurityDefinition("Bearer", scheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = Array.Empty<string>() });
});

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddAllegroAuth(builder.Configuration, builder.Environment);

builder.Services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database");

// CORS: la app Flutter es nativa (no usa CORS). La web admin sí, por lo que solo
// se permiten los orígenes configurados en Cors:AllowedOrigins. Si no hay ninguno
// configurado y estamos en desarrollo, se permite cualquiera para facilitar pruebas.
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("allow-app", policy =>
    {
        if (allowedOrigins.Length > 0)
            policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
        else if (builder.Environment.IsDevelopment())
            policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
        // En producción sin orígenes configurados: CORS cerrado (sin orígenes permitidos).
    });
});

// Rate limiting para operaciones administrativas sensibles (creación de usuarios,
// enlaces de activación, revocación de sesiones...). Limita por usuario autenticado.
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("admin-sensitive", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.User?.Identity?.Name
                ?? httpContext.Connection.RemoteIpAddress?.ToString()
                ?? "anonymous",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 20,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            }));
});

var app = builder.Build();

// Comando CLI (no levanta el servidor): asignación del primer administrador.
if (args.Length > 0 && args[0] == Allegro.Api.Bootstrap.BootstrapAdminCommand.Name)
{
    return await Allegro.Api.Bootstrap.BootstrapAdminCommand.RunAsync(app.Services, args);
}

app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("allow-app");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Liveness (sin tocar la base) y readiness (verifica la base).
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");

await ApplyMigrationsAndSeedAsync(app);

app.Run();

static async Task ApplyMigrationsAndSeedAsync(WebApplication app)
{
    var applyMigrations = ReadBool(app.Configuration["APPLY_MIGRATIONS"], defaultValue: true);
    var seedDemo = ReadBool(app.Configuration["SEED_DEMO_DATA"], defaultValue: false);
    if (!applyMigrations) return;

    using var scope = app.Services.CreateScope();
    var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("Startup");
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<AllegroDbContext>();
        await db.Database.MigrateAsync();

        var seeder = scope.ServiceProvider.GetRequiredService<DataSeeder>();
        await seeder.SeedAsync(includeDemoReservations: seedDemo);
        logger.LogInformation("Migraciones aplicadas. Seed demo: {Seed}.", seedDemo);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error al aplicar migraciones o seed al iniciar.");
        throw;
    }
}

static bool ReadBool(string? value, bool defaultValue) =>
    string.IsNullOrWhiteSpace(value) ? defaultValue : value.Trim().ToLowerInvariant() is "true" or "1" or "yes";

/// <summary>Expuesto para las pruebas de integración.</summary>
public partial class Program { }
