using Allegro.Application.Dtos;
using FluentValidation;

namespace Allegro.Application.Validation;

public class CreateReservationValidator : AbstractValidator<CreateReservationDto>
{
    public CreateReservationValidator()
    {
        RuleFor(x => x.GuestName).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Phone).NotEmpty().MaximumLength(40);
        RuleFor(x => x.DomeId).NotEmpty();
        RuleFor(x => x.GuestCount).GreaterThan(0);
        RuleFor(x => x.LodgingPrice).GreaterThanOrEqualTo(0);
        RuleFor(x => x.CheckOut)
            .GreaterThan(x => x.CheckIn)
            .WithMessage("La fecha de salida debe ser posterior a la fecha de llegada.");
    }
}

public class UpdateReservationValidator : AbstractValidator<UpdateReservationDto>
{
    public UpdateReservationValidator()
    {
        RuleFor(x => x.GuestName).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Phone).NotEmpty().MaximumLength(40);
        RuleFor(x => x.DomeId).NotEmpty();
        RuleFor(x => x.GuestCount).GreaterThan(0);
        RuleFor(x => x.LodgingPrice).GreaterThanOrEqualTo(0);
        RuleFor(x => x.CheckOut)
            .GreaterThan(x => x.CheckIn)
            .WithMessage("La fecha de salida debe ser posterior a la fecha de llegada.");
    }
}

public class CreatePaymentValidator : AbstractValidator<CreatePaymentDto>
{
    public CreatePaymentValidator()
    {
        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .WithMessage("El valor del abono debe ser mayor que cero.");
    }
}

public class CreateConsumptionValidator : AbstractValidator<CreateConsumptionDto>
{
    public CreateConsumptionValidator()
    {
        RuleFor(x => x.ProductId).NotEmpty();
        RuleFor(x => x.Quantity).GreaterThan(0);
    }
}

public class UpsertProductValidator : AbstractValidator<UpsertProductDto>
{
    public UpsertProductValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.CategoryId).NotEmpty().WithMessage("La categoría es obligatoria.");
        RuleFor(x => x.CurrentPrice).GreaterThanOrEqualTo(0);
    }
}

public class UpsertDomeValidator : AbstractValidator<UpsertDomeDto>
{
    public UpsertDomeValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(80);
        RuleFor(x => x.MaxCapacity).GreaterThan(0);
    }
}

public class CreateDomeBlockValidator : AbstractValidator<CreateDomeBlockDto>
{
    public CreateDomeBlockValidator()
    {
        RuleFor(x => x.DomeId).NotEmpty();
        RuleFor(x => x.Reason).NotEmpty().MaximumLength(200);
        RuleFor(x => x.EndDate)
            .GreaterThan(x => x.StartDate)
            .WithMessage("La fecha final debe ser posterior a la inicial.");
    }
}
