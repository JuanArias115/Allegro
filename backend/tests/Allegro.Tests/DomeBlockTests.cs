using Allegro.Application.Dtos;
using Allegro.Domain;
using FluentAssertions;
using Xunit;

namespace Allegro.Tests;

public class DomeBlockTests
{
    private static CreateReservationDto Booking(DateOnly inDate, DateOnly outDate, Guid? dome = null) =>
        new("Huésped Demo", "+573000000000", dome ?? TestHarness.Dome1, inDate, outDate, 2, 300000m, null);

    private static CreateDomeBlockDto Block(DateOnly start, DateOnly end, Guid? dome = null) =>
        new(dome ?? TestHarness.Dome1, start, end, "Mantenimiento");

    [Fact]
    public async Task Block_prevents_overlapping_reservation()
    {
        var h = new TestHarness();
        await h.Blocks().CreateAsync(Block(new(2026, 7, 10), new(2026, 7, 15)));

        var act = async () => await h.Reservations().CreateAsync(Booking(new(2026, 7, 12), new(2026, 7, 14)));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*bloquead*");
    }

    [Fact]
    public async Task Block_over_existing_reservation_is_rejected()
    {
        var h = new TestHarness();
        await h.Reservations().CreateAsync(Booking(new(2026, 7, 1), new(2026, 7, 5)));

        var act = async () => await h.Blocks().CreateAsync(Block(new(2026, 7, 3), new(2026, 7, 8)));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*reserva activa*");
    }

    [Fact]
    public async Task Overlapping_blocks_are_rejected()
    {
        var h = new TestHarness();
        await h.Blocks().CreateAsync(Block(new(2026, 7, 10), new(2026, 7, 15)));

        var act = async () => await h.Blocks().CreateAsync(Block(new(2026, 7, 14), new(2026, 7, 20)));

        await act.Should().ThrowAsync<DomainException>().WithMessage("*bloqueo*");
    }

    [Fact]
    public async Task Availability_reflects_blocked_range()
    {
        var h = new TestHarness();
        await h.Blocks().CreateAsync(Block(new(2026, 7, 10), new(2026, 7, 15)));

        var availability = await h.Reservations()
            .CheckAvailabilityAsync(TestHarness.Dome1, new(2026, 7, 11), new(2026, 7, 13), null);

        availability.IsAvailable.Should().BeFalse();
        availability.BlockedRanges.Should().ContainSingle();
    }

    [Fact]
    public async Task Block_on_other_dome_does_not_affect_availability()
    {
        var h = new TestHarness();
        await h.Blocks().CreateAsync(Block(new(2026, 7, 10), new(2026, 7, 15), TestHarness.Dome2));

        var availability = await h.Reservations()
            .CheckAvailabilityAsync(TestHarness.Dome1, new(2026, 7, 11), new(2026, 7, 13), null);

        availability.IsAvailable.Should().BeTrue();
    }
}
