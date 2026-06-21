using Allegro.Application.Dtos;
using Allegro.Domain;
using Allegro.Infrastructure.Persistence;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

public class BalanceAndCheckoutTests
{
    private static CreateReservationDto Booking(decimal lodging) =>
        new("Huésped Demo", "+573000000000", TestHarness.Dome1,
            new(2026, 7, 1), new(2026, 7, 5), 2, lodging, null);

    [Fact]
    public async Task Balance_is_lodging_plus_consumptions_minus_payments()
    {
        var h = new TestHarness();
        var product = h.AddProduct("Vino", 60000m);

        var r = await h.Reservations().CreateAsync(Booking(400000m));
        await h.Reservations().AddConsumptionAsync(r.Id, new CreateConsumptionDto(product.Id, 2, null)); // +120000
        await h.Reservations().AddPaymentAsync(r.Id, new CreatePaymentDto(200000m, PaymentMethod.Cash, null, null));

        var detail = await h.Reservations().GetByIdAsync(r.Id);

        detail!.TotalConsumptions.Should().Be(120000m);
        detail.TotalDue.Should().Be(520000m);     // 400000 + 120000
        detail.TotalPaid.Should().Be(200000m);
        detail.Balance.Should().Be(320000m);       // 520000 - 200000
    }

    [Fact]
    public async Task Multiple_payments_accumulate()
    {
        var h = new TestHarness();

        var r = await h.Reservations().CreateAsync(Booking(300000m));
        await h.Reservations().AddPaymentAsync(r.Id, new CreatePaymentDto(100000m, PaymentMethod.Cash, null, null));
        await h.Reservations().AddPaymentAsync(r.Id, new CreatePaymentDto(50000m, PaymentMethod.Transfer, null, null));

        var detail = await h.Reservations().GetByIdAsync(r.Id);

        detail!.Payments.Should().HaveCount(2);
        detail.TotalPaid.Should().Be(150000m);
        detail.Balance.Should().Be(150000m);
    }

    [Fact]
    public async Task Consumption_price_is_frozen_when_catalog_price_changes()
    {
        var h = new TestHarness();
        var product = h.AddProduct("Vino", 60000m);

        var r = await h.Reservations().CreateAsync(Booking(400000m));
        await h.Reservations().AddConsumptionAsync(r.Id, new CreateConsumptionDto(product.Id, 1, null));

        // Cambiamos el precio de catálogo después del consumo.
        await h.Products().UpdateAsync(product.Id,
            new UpsertProductDto("Vino", ProductCategorySeedData.Bebidas, 99000m, true, null));

        var detail = await h.Reservations().GetByIdAsync(r.Id);

        detail!.Consumptions.Single().UnitPrice.Should().Be(60000m);
        detail.TotalConsumptions.Should().Be(60000m);
    }

    [Fact]
    public async Task Checkout_registers_final_payment_and_marks_completed()
    {
        var h = new TestHarness();

        var r = await h.Reservations().CreateAsync(Booking(400000m));
        await h.Reservations().AddPaymentAsync(r.Id, new CreatePaymentDto(150000m, PaymentMethod.Cash, null, null));

        var result = await h.Reservations().CheckoutAsync(r.Id,
            new CreatePaymentDto(250000m, PaymentMethod.Transfer, "Saldo final", null));

        result.Status.Should().Be(ReservationStatus.Completed);
        result.Balance.Should().Be(0m);
        result.TotalPaid.Should().Be(400000m);
    }

    [Fact]
    public async Task Checkout_summary_does_not_change_status()
    {
        var h = new TestHarness();

        var r = await h.Reservations().CreateAsync(Booking(400000m));
        var summary = await h.Reservations().GetCheckoutSummaryAsync(r.Id);

        summary!.Status.Should().Be(ReservationStatus.Confirmed);
        var detail = await h.Reservations().GetByIdAsync(r.Id);
        detail!.Status.Should().Be(ReservationStatus.Confirmed); // sigue activa
    }

    [Fact]
    public async Task Negative_payment_is_rejected()
    {
        var h = new TestHarness();

        var r = await h.Reservations().CreateAsync(Booking(400000m));
        var act = async () => await h.Reservations().AddPaymentAsync(r.Id,
            new CreatePaymentDto(-100m, PaymentMethod.Cash, null, null));

        await act.Should().ThrowAsync<DomainException>();
    }
}
