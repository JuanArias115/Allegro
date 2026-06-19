using Allegro.Application.Dtos;
using Allegro.Domain;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

public class AvailabilityTests
{
    private static CreateReservationDto Booking(DateOnly inDate, DateOnly outDate, Guid? dome = null) =>
        new("Huésped Demo", "+573000000000", dome ?? TestHarness.Dome1, inDate, outDate, 2, 300000m, null);

    [Fact]
    public async Task Crossing_reservations_on_same_dome_are_rejected()
    {
        var h = new TestHarness();
        await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5)));

        var act = async () => await h.Reservations().CreateAsync(Booking(new(2026, 7, 3), new(2026, 7, 8)));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*se cruza*");
    }

    [Fact]
    public async Task Adjacent_reservations_are_allowed()
    {
        var h = new TestHarness();
        await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5)));

        // La salida del primero coincide con la llegada del segundo: NO se cruzan.
        var second = await h.Reservations().CreateAsync(Booking(new(2026, 7, 5), new(2026, 7, 8)));

        second.Should().NotBeNull();
    }

    [Fact]
    public async Task Same_dates_on_different_domes_are_allowed()
    {
        var h = new TestHarness();
        await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5), TestHarness.Dome1));
        var other = await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5), TestHarness.Dome2));

        other.Should().NotBeNull();
    }

    [Fact]
    public async Task Cancelled_reservation_does_not_block_availability()
    {
        var h = new TestHarness();
        var first = await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5)));
        await h.Reservations().ChangeStatusAsync(first.Id, ReservationStatus.Cancelled);

        var availability = await h.Reservations()
            .CheckAvailabilityAsync(TestHarness.Dome1, new(2026, 7, 1), new(2026, 7, 5), null);

        availability.IsAvailable.Should().BeTrue();
        availability.Conflicts.Should().BeEmpty();
    }

    [Fact]
    public async Task Checkout_date_must_be_after_checkin()
    {
        var h = new TestHarness();
        var act = async () => await h.Reservations().CreateAsync(Booking(new(2026, 7, 5), new(2026, 7, 5)));

        await act.Should().ThrowAsync<DomainException>();
    }

    [Fact]
    public async Task Update_excludes_itself_from_overlap_check()
    {
        var h = new TestHarness();
        var created = await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5)));
        var update = new UpdateReservationDto("Huésped Demo", "+573000000000",
            TestHarness.Dome1, new(2026, 7, 2), new(2026, 7, 6), 2, 300000m, null);

        var updated = await h.Reservations().UpdateAsync(created.Id, update);

        updated.CheckOut.Should().Be(new DateOnly(2026, 7, 6));
    }
}
