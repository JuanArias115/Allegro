using Allegro.Application.Dtos;
using Allegro.Application.Services;
using Allegro.Domain;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

public class ReportTests
{
    private static readonly DateOnly JulFrom = new(2026, 7, 1);
    private static readonly DateOnly JulTo = new(2026, 8, 1); // exclusivo

    private static CreateReservationDto Booking(DateOnly inDate, DateOnly outDate, decimal price, Guid? dome = null) =>
        new("Huésped", "+573000000000", dome ?? TestHarness.Dome1, inDate, outDate, 2, price, null);

    private static CreatePaymentDto Payment(decimal amount, DateOnly date) =>
        new(amount, PaymentMethod.Cash, null, new DateTime(date.Year, date.Month, date.Day, 12, 0, 0, DateTimeKind.Utc));

    [Fact]
    public async Task Summary_with_no_data_is_all_zeros()
    {
        var h = new TestHarness();

        var s = await h.Reports().GetSummaryAsync(JulFrom, JulTo);

        s.ReservationsCount.Should().Be(0);
        s.OccupiedNights.Should().Be(0);
        s.ReservedValue.Should().Be(0);
        s.PaymentsReceived.Should().Be(0);
        s.OccupancyRate.Should().Be(0);
    }

    [Fact]
    public async Task Cancelled_reservation_excluded_from_occupancy_but_real_payment_still_counts()
    {
        var h = new TestHarness();
        var r = await h.Reservations().CreateAsync(Booking(new(2026, 7, 10), new(2026, 7, 14), 400000m));
        await h.Reservations().AddPaymentAsync(r.Id, Payment(100000m, new(2026, 7, 10)));
        await h.Reservations().ChangeStatusAsync(r.Id, ReservationStatus.Cancelled);

        var s = await h.Reports().GetSummaryAsync(JulFrom, JulTo);

        s.OccupiedNights.Should().Be(0);          // cancelada: fuera de ocupación
        s.ReservedValue.Should().Be(0);           // y fuera de ingreso esperado
        s.Cancellations.Should().Be(1);
        s.PaymentsReceived.Should().Be(100000m);  // el pago real sí se refleja
    }

    [Fact]
    public async Task Reservation_crossing_month_counts_only_nights_in_range()
    {
        var h = new TestHarness();
        // [Jun 28, Jul 3): solapa julio en 2 noches (Jul1, Jul2).
        await h.Reservations().CreateAsync(Booking(new(2026, 6, 28), new(2026, 7, 3), 500000m));

        var s = await h.Reports().GetSummaryAsync(JulFrom, JulTo);

        s.OccupiedNights.Should().Be(2);
        s.ReservationsCount.Should().Be(0); // llegada en junio: no se atribuye a julio
        s.ReservedValue.Should().Be(0);
    }

    [Fact]
    public async Task Partial_payments_are_summed()
    {
        var h = new TestHarness();
        var r = await h.Reservations().CreateAsync(Booking(new(2026, 7, 5), new(2026, 7, 8), 300000m));
        await h.Reservations().AddPaymentAsync(r.Id, Payment(100000m, new(2026, 7, 5)));
        await h.Reservations().AddPaymentAsync(r.Id, Payment(50000m, new(2026, 7, 6)));

        var s = await h.Reports().GetSummaryAsync(JulFrom, JulTo);

        s.PaymentsReceived.Should().Be(150000m);
        s.PendingBalance.Should().Be(150000m); // 300000 - 150000
    }

    [Fact]
    public async Task Products_sold_are_aggregated_and_ranked()
    {
        var h = new TestHarness();
        var agua = h.AddProduct("Agua", 5000m);
        var cerveza = h.AddProduct("Cerveza", 8000m);
        var r = await h.Reservations().CreateAsync(Booking(new(2026, 7, 5), new(2026, 7, 8), 300000m));
        await h.Reservations().AddConsumptionAsync(r.Id,
            new CreateConsumptionDto(agua.Id, 3, new DateTime(2026, 7, 6, 12, 0, 0, DateTimeKind.Utc)));
        await h.Reservations().AddConsumptionAsync(r.Id,
            new CreateConsumptionDto(cerveza.Id, 2, new DateTime(2026, 7, 6, 12, 0, 0, DateTimeKind.Utc)));

        var p = await h.Reports().GetProductsAsync(JulFrom, JulTo);

        p.TotalQuantity.Should().Be(5);
        p.TotalValue.Should().Be(31000m); // 3*5000 + 2*8000
        p.Items.First().ProductName.Should().Be("Cerveza"); // mayor valor primero
    }

    [Fact]
    public async Task Occupancy_rate_is_occupied_over_available()
    {
        var h = new TestHarness();
        // Rango de 10 noches, 2 domos => 20 noches disponibles. 4 noches ocupadas => 0.2
        var from = new DateOnly(2026, 7, 1);
        var to = new DateOnly(2026, 7, 11);
        await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5), 400000m, TestHarness.Dome1));

        var occ = await h.Reports().GetOccupancyAsync(from, to);

        occ.OccupiedNights.Should().Be(4);
        occ.AvailableNights.Should().Be(20);
        occ.OccupancyRate.Should().Be(0.2m);
        occ.Domes.Should().HaveCount(2);
    }

    [Fact]
    public async Task Dome_blocks_reduce_available_nights()
    {
        var h = new TestHarness();
        var from = new DateOnly(2026, 7, 1);
        var to = new DateOnly(2026, 7, 11); // 10 noches × 2 domos
        await h.Blocks().CreateAsync(new CreateDomeBlockDto(
            TestHarness.Dome1,
            new DateOnly(2026, 7, 3),
            new DateOnly(2026, 7, 6),
            "Mantenimiento"));

        var occ = await h.Reports().GetOccupancyAsync(from, to);
        var summary = await h.Reports().GetSummaryAsync(from, to);

        occ.AvailableNights.Should().Be(17);
        summary.AvailableNights.Should().Be(17);
        occ.Domes.Single(d => d.DomeId == TestHarness.Dome1).AvailableNights.Should().Be(7);
    }

    [Fact]
    public async Task Csv_export_contains_summary_rows()
    {
        var h = new TestHarness();
        await h.Reservations().CreateAsync(Booking(new(2026, 7, 5), new(2026, 7, 8), 300000m));

        var summary = await h.Reports().GetSummaryAsync(JulFrom, JulTo);
        var occupancy = await h.Reports().GetOccupancyAsync(JulFrom, JulTo);
        var products = await h.Reports().GetProductsAsync(JulFrom, JulTo);
        var csv = ReportCsv.Build(summary, occupancy, products);

        csv.Should().Contain("Periodo");
        csv.Should().Contain("Pagos recibidos");
        csv.Should().Contain("Ocupacion,Porcentaje");
    }

    [Fact]
    public async Task Invalid_range_is_rejected()
    {
        var h = new TestHarness();
        var act = async () => await h.Reports().GetSummaryAsync(JulTo, JulFrom);
        await act.Should().ThrowAsync<DomainException>();
    }
}
