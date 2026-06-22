namespace Allegro.Application.Dtos;

/// <summary>
/// Resumen del periodo [From, To) (inicio inclusivo, fin exclusivo), en zona
/// America/Bogota. Definiciones:
/// - ReservationsCount/ReservedValue/NightsReserved/PendingBalance: reservas NO
///   canceladas cuya llegada (CheckIn) cae en el rango (cada reserva en un solo
///   periodo: evita doble conteo entre meses).
/// - Cancellations: reservas canceladas con CheckIn en el rango.
/// - OccupiedNights: noches de solapamiento entre cada estadía no cancelada y el
///   rango (conteo por noche, sin doble conteo).
/// - PaymentsReceived: pagos cuya fecha (Bogota) cae en el rango, INDEPENDIENTE del
///   estado de la reserva (un pago válido cuenta aunque luego se cancele la reserva).
/// - ProductSalesValue: consumos cuya fecha (Bogota) cae en el rango.
/// </summary>
public record ReportSummaryDto(
    DateOnly From,
    DateOnly To,
    int ReservationsCount,
    int Cancellations,
    int NightsReserved,
    int OccupiedNights,
    int AvailableNights,
    decimal OccupancyRate,
    decimal ReservedValue,
    decimal PaymentsReceived,
    decimal PendingBalance,
    decimal ProductSalesValue);

public record OccupancyByDomeDto(
    Guid DomeId,
    string DomeName,
    int OccupiedNights,
    int AvailableNights,
    decimal OccupancyRate);

public record OccupancyReportDto(
    DateOnly From,
    DateOnly To,
    int OccupiedNights,
    int AvailableNights,
    decimal OccupancyRate,
    IReadOnlyList<OccupancyByDomeDto> Domes);

public record PaymentBucketDto(DateOnly Date, decimal Amount);

public record PaymentsReportDto(
    DateOnly From,
    DateOnly To,
    decimal Total,
    IReadOnlyList<PaymentBucketDto> ByDay);

public record ProductSalesDto(Guid ProductId, string ProductName, int Quantity, decimal Value);

public record ProductsReportDto(
    DateOnly From,
    DateOnly To,
    int TotalQuantity,
    decimal TotalValue,
    IReadOnlyList<ProductSalesDto> Items);
