using Allegro.Domain;

namespace Allegro.Application.Dtos;

public record PaymentDto(
    Guid Id,
    decimal Amount,
    DateTime PaidAt,
    PaymentMethod Method,
    string? Note);

public record CreatePaymentDto(
    decimal Amount,
    PaymentMethod Method,
    string? Note,
    DateTime? PaidAt);

public record ConsumptionDto(
    Guid Id,
    Guid ProductId,
    string ProductName,
    int Quantity,
    decimal UnitPrice,
    decimal Subtotal,
    DateTime ConsumedAt);

public record CreateConsumptionDto(
    Guid ProductId,
    int Quantity,
    DateTime? ConsumedAt);

/// <summary>Resumen compacto para listados (Hoy, Calendario, Historial).</summary>
public record ReservationSummaryDto(
    Guid Id,
    string GuestName,
    string Phone,
    Guid DomeId,
    string DomeName,
    DateOnly CheckIn,
    DateOnly CheckOut,
    int GuestCount,
    ReservationStatus Status,
    decimal LodgingPrice,
    decimal TotalConsumptions,
    decimal TotalPaid,
    decimal Balance);

/// <summary>Detalle completo de una reserva, con abonos y consumos.</summary>
public record ReservationDto(
    Guid Id,
    string GuestName,
    string Phone,
    Guid DomeId,
    string DomeName,
    DateOnly CheckIn,
    DateOnly CheckOut,
    int GuestCount,
    decimal LodgingPrice,
    ReservationStatus Status,
    string? Notes,
    decimal TotalConsumptions,
    decimal TotalDue,
    decimal TotalPaid,
    decimal Balance,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    IReadOnlyList<PaymentDto> Payments,
    IReadOnlyList<ConsumptionDto> Consumptions);

public record CreateReservationDto(
    string GuestName,
    string Phone,
    Guid DomeId,
    DateOnly CheckIn,
    DateOnly CheckOut,
    int GuestCount,
    decimal LodgingPrice,
    string? Notes);

public record UpdateReservationDto(
    string GuestName,
    string Phone,
    Guid DomeId,
    DateOnly CheckIn,
    DateOnly CheckOut,
    int GuestCount,
    decimal LodgingPrice,
    string? Notes);

public record ChangeStatusDto(ReservationStatus Status);

/// <summary>Resumen de checkout (cuenta de cierre).</summary>
public record CheckoutSummaryDto(
    Guid ReservationId,
    string GuestName,
    string DomeName,
    DateOnly CheckIn,
    DateOnly CheckOut,
    decimal LodgingPrice,
    IReadOnlyList<ConsumptionDto> Consumptions,
    decimal TotalConsumptions,
    decimal TotalDue,
    decimal TotalPaid,
    decimal Balance,
    ReservationStatus Status);

public static class ReservationMapping
{
    public static PaymentDto ToDto(this Payment p) =>
        new(p.Id, p.Amount, p.PaidAt, p.Method, p.Note);

    public static ConsumptionDto ToDto(this Consumption c) =>
        new(c.Id, c.ProductId, c.ProductName, c.Quantity, c.UnitPrice, c.Subtotal, c.ConsumedAt);

    public static ReservationSummaryDto ToSummary(this Reservation r) =>
        new(r.Id, r.GuestName, r.Phone, r.DomeId, r.Dome?.Name ?? string.Empty,
            r.CheckIn, r.CheckOut, r.GuestCount, r.Status,
            r.LodgingPrice, r.TotalConsumptions, r.TotalPaid, r.Balance);

    public static ReservationDto ToDto(this Reservation r) =>
        new(r.Id, r.GuestName, r.Phone, r.DomeId, r.Dome?.Name ?? string.Empty,
            r.CheckIn, r.CheckOut, r.GuestCount, r.LodgingPrice, r.Status, r.Notes,
            r.TotalConsumptions, r.TotalDue, r.TotalPaid, r.Balance,
            r.CreatedAt, r.UpdatedAt,
            r.Payments.OrderBy(p => p.PaidAt).Select(p => p.ToDto()).ToList(),
            r.Consumptions.OrderBy(c => c.ConsumedAt).Select(c => c.ToDto()).ToList());

    public static CheckoutSummaryDto ToCheckoutSummary(this Reservation r) =>
        new(r.Id, r.GuestName, r.Dome?.Name ?? string.Empty, r.CheckIn, r.CheckOut,
            r.LodgingPrice,
            r.Consumptions.OrderBy(c => c.ConsumedAt).Select(c => c.ToDto()).ToList(),
            r.TotalConsumptions, r.TotalDue, r.TotalPaid, r.Balance, r.Status);
}
