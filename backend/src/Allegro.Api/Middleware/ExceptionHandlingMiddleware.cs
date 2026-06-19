using System.Text.Json;
using Allegro.Domain;

namespace Allegro.Api.Middleware;

/// <summary>
/// Manejo centralizado de errores. Traduce las excepciones de dominio a respuestas
/// HTTP claras y consistentes; los errores no controlados devuelven 500 sin filtrar
/// detalles internos.
/// </summary>
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (DomainException ex)
        {
            await WriteProblem(context, StatusCodes.Status409Conflict, "Regla de negocio", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error no controlado.");
            await WriteProblem(context, StatusCodes.Status500InternalServerError,
                "Error interno", "Ocurrió un error inesperado.");
        }
    }

    private static async Task WriteProblem(HttpContext context, int status, string title, string detail)
    {
        if (context.Response.HasStarted) return;
        context.Response.Clear();
        context.Response.StatusCode = status;
        context.Response.ContentType = "application/problem+json";
        var payload = new { title, detail, status };
        await context.Response.WriteAsync(JsonSerializer.Serialize(payload));
    }
}
