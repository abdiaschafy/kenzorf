using FluentValidation;
using KENZORF.Application.Contracts;
using KENZORF.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace KENZORF.Application;

/// <summary>Enregistrement des services applicatifs et des validateurs FluentValidation.</summary>
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly, includeInternalTypes: true);

        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<ICatalogService, CatalogService>();
        services.AddScoped<ICartService, CartService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IAddressService, AddressService>();
        services.AddScoped<IDashboardService, DashboardService>();
        services.AddScoped<IAdminProductService, AdminProductService>();
        services.AddScoped<IAdminOrderService, AdminOrderService>();
        services.AddScoped<IImageUploadService, ImageUploadService>();

        return services;
    }
}
