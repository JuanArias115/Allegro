using Allegro.Application.Services;
using Allegro.Application.Validation;
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;

namespace Allegro.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IDomeService, DomeService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IReservationService, ReservationService>();

        services.AddValidatorsFromAssemblyContaining<CreateReservationValidator>();

        return services;
    }
}
