using System.Globalization;
using System.Text;
using Allegro.Application.Dtos;

namespace Allegro.Application.Services;

/// <summary>Construye el CSV de reportería (sin dependencias de la capa web, para poder probarlo).</summary>
public static class ReportCsv
{
    public static string Build(ReportSummaryDto summary, OccupancyReportDto occupancy, ProductsReportDto products)
    {
        var inv = CultureInfo.InvariantCulture;
        var sb = new StringBuilder();
        sb.AppendLine("Seccion,Concepto,Valor");
        sb.AppendLine($"Periodo,Desde,{summary.From:yyyy-MM-dd}");
        sb.AppendLine($"Periodo,Hasta (exclusivo),{summary.To:yyyy-MM-dd}");
        sb.AppendLine($"Reservas,Cantidad,{summary.ReservationsCount}");
        sb.AppendLine($"Reservas,Cancelaciones,{summary.Cancellations}");
        sb.AppendLine($"Reservas,Noches reservadas,{summary.NightsReserved}");
        sb.AppendLine($"Ocupacion,Noches ocupadas,{summary.OccupiedNights}");
        sb.AppendLine($"Ocupacion,Noches disponibles,{summary.AvailableNights}");
        sb.AppendLine($"Ocupacion,Porcentaje,{summary.OccupancyRate.ToString(inv)}");
        sb.AppendLine($"Dinero,Valor reservado,{summary.ReservedValue.ToString(inv)}");
        sb.AppendLine($"Dinero,Pagos recibidos,{summary.PaymentsReceived.ToString(inv)}");
        sb.AppendLine($"Dinero,Saldo pendiente,{summary.PendingBalance.ToString(inv)}");
        sb.AppendLine($"Dinero,Ventas de productos,{summary.ProductSalesValue.ToString(inv)}");

        foreach (var d in occupancy.Domes)
            sb.AppendLine($"Ocupacion por domo,{Escape(d.DomeName)},{d.OccupancyRate.ToString(inv)}");

        foreach (var p in products.Items)
            sb.AppendLine($"Producto vendido,{Escape(p.ProductName)},{p.Quantity} | {p.Value.ToString(inv)}");

        return sb.ToString();
    }

    private static string Escape(string value) =>
        value.Contains(',') || value.Contains('"')
            ? $"\"{value.Replace("\"", "\"\"")}\""
            : value;
}
