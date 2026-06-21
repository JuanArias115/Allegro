using Allegro.Application.Abstractions;

namespace Allegro.Infrastructure;

/// <summary>
/// Reloj del sistema. "Hoy" se calcula en la zona horaria del negocio
/// (variable de entorno BUSINESS_TIMEZONE, por defecto America/Bogota),
/// aunque los instantes se almacenan siempre en UTC.
/// </summary>
public class SystemClock : IClock
{
    private readonly TimeZoneInfo _tz;

    public SystemClock()
    {
        var id = Environment.GetEnvironmentVariable("BUSINESS_TIMEZONE") ?? "America/Bogota";
        try
        {
            _tz = TimeZoneInfo.FindSystemTimeZoneById(id);
        }
        catch
        {
            _tz = TimeZoneInfo.Utc;
        }
    }

    public DateTime UtcNow => DateTime.UtcNow;

    public DateOnly Today =>
        DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, _tz));

    public DateOnly ToBusinessDate(DateTime utc)
    {
        var asUtc = utc.Kind == DateTimeKind.Utc ? utc : DateTime.SpecifyKind(utc, DateTimeKind.Utc);
        return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(asUtc, _tz));
    }
}
