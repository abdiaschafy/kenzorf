using KENZORF.Application.Contracts;
using KENZORF.Infrastructure.Auth;
using KENZORF.Infrastructure.Identity;
using KENZORF.Infrastructure.Payments;
using KENZORF.Infrastructure.Persistence;
using KENZORF.Infrastructure.Storage;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace KENZORF.Infrastructure;

/// <summary>Enregistrement de la persistance, d'Identity, des jetons, du paiement et du stockage.</summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services,
        IConfiguration configuration, IHostEnvironment environment)
    {
        var connectionString = configuration.GetConnectionString("Default")
            ?? "Host=localhost;Port=5432;Database=kenzorf;Username=kenzorf;Password=kenzorf";

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(connectionString, npgsql =>
                npgsql.MigrationsAssembly(typeof(AppDbContext).Assembly.FullName)));

        // Exposition des abstractions Application vers le même DbContext (scopé).
        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());
        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<AppDbContext>());

        services
            .AddIdentityCore<ApplicationUser>(options =>
            {
                options.Password.RequiredLength = 8;
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequireUppercase = true;
                options.Password.RequireLowercase = true;
                options.Password.RequireDigit = true;
                options.User.RequireUniqueEmail = true;
            })
            .AddRoles<ApplicationRole>()
            .AddEntityFrameworkStores<AppDbContext>();

        // Options.
        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.Configure<KPayOptions>(configuration.GetSection(KPayOptions.SectionName));
        services.Configure<StorageOptions>(configuration.GetSection(StorageOptions.SectionName));

        // Auth.
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IIdentityService, IdentityService>();

        // Stockage des images.
        services.AddScoped<IImageStorage, LocalImageStorage>();

        // Passerelle de paiement : Fake en Development sans clés, KPay sinon (fail-closed en prod).
        RegisterPaymentGateway(services, configuration, environment);

        return services;
    }

    private static void RegisterPaymentGateway(IServiceCollection services, IConfiguration configuration,
        IHostEnvironment environment)
    {
        var kpaySection = configuration.GetSection(KPayOptions.SectionName);
        var options = kpaySection.Get<KPayOptions>() ?? new KPayOptions();

        var useFake = environment.IsDevelopment() && !options.HasCredentials;

        if (useFake)
        {
            services.AddScoped<IPaymentGateway, FakePaymentGateway>();
        }
        else
        {
            // En production sans clés, le gateway KPay reste enregistré mais échoue proprement (fail-closed).
            services.AddHttpClient<IPaymentGateway, KPayPaymentGateway>(client =>
            {
                if (!string.IsNullOrWhiteSpace(options.BaseUrl))
                {
                    client.BaseAddress = new Uri(options.BaseUrl.TrimEnd('/') + "/");
                }

                client.Timeout = TimeSpan.FromSeconds(30);
            });
        }
    }
}
