using System.Text;
using System.Text.Json.Serialization;
using KENZORF.Api.Auth;
using KENZORF.Api.Configuration;
using KENZORF.Api.Middleware;
using KENZORF.Application;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Infrastructure;
using KENZORF.Infrastructure.Auth;
using KENZORF.Infrastructure.Persistence;
using KENZORF.Infrastructure.Seed;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Serilog (console structuré).
builder.Host.UseSerilog((context, configuration) =>
    configuration.ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .WriteTo.Console());

const string CorsPolicy = "kenzorf-clients";

// JSON : camelCase + enums en string.
builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.DictionaryKeyPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "KENZORF API",
        Version = "v1",
        Description = "API de la boutique KENZORF (catalogue, panier, commandes, paiement KPay, auth).",
    });

    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Bearer. Saisir uniquement le token (sans le préfixe 'Bearer ').",
        Reference = new OpenApiReference { Id = "Bearer", Type = ReferenceType.SecurityScheme },
    };

    options.AddSecurityDefinition("Bearer", scheme);
    options.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = Array.Empty<string>() });
});

// Application + Infrastructure.
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration, builder.Environment);

// Authentification JWT Bearer.
var jwtOptions = builder.Configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>() ?? new JwtOptions();

// Fail-closed : hors Development, refuser de démarrer si le secret JWT est faible/manquant/de démo.
// (docker-compose/.env imposent déjà la présence de Jwt__Key ; ce garde-fou défend en profondeur.)
if (!builder.Environment.IsDevelopment())
{
    var key = jwtOptions.Key ?? string.Empty;
    var keyByteLength = Encoding.UTF8.GetByteCount(key);

    if (string.IsNullOrWhiteSpace(key) || keyByteLength < 32
        || key.Contains("change", StringComparison.OrdinalIgnoreCase))
    {
        throw new InvalidOperationException(
            "Configuration JWT invalide : 'Jwt:Key' doit être défini, faire au moins 32 octets et ne pas " +
            "contenir la valeur de démonstration « change ». Générer un secret fort (ex. openssl rand -base64 48).");
    }
}

builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidAudience = jwtOptions.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.Key ?? string.Empty)),
            ClockSkew = TimeSpan.FromSeconds(30),
            RoleClaimType = System.Security.Claims.ClaimTypes.Role,
            NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier,
        };
    });

builder.Services.AddAuthorizationBuilder()
    .AddPolicy(AppRoles.Admin, policy => policy.RequireRole(AppRoles.Admin))
    .AddPolicy(AppRoles.Customer, policy => policy.RequireRole(AppRoles.Customer));

// CORS piloté par configuration (section "Cors:AllowedOrigins"). Jamais d'origine « * » avec credentials.
// Défaut : back-office Angular local (http://localhost:4200).
var corsOptions = builder.Configuration.GetSection(CorsOptions.SectionName).Get<CorsOptions>() ?? new CorsOptions();
var allowedOrigins = corsOptions.AllowedOrigins is { Length: > 0 }
    ? corsOptions.AllowedOrigins
    : new[] { "http://localhost:4200" };

builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy, policy =>
    {
        policy.WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

// Rate limiting des endpoints sensibles (auth + webhook). Relâché en Development/Testing pour les tests e2e.
var relaxRateLimiting = builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing");
builder.Services.AddKenzorfRateLimiting(relaxRateLimiting);

var app = builder.Build();

// Pipeline.
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<SecurityHeadersMiddleware>();

// HSTS hors développement (le reverse proxy gère TLS ; renforce la posture HTTPS).
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(ui =>
    {
        ui.SwaggerEndpoint("/swagger/v1/swagger.json", "KENZORF API v1");
    });
}

app.UseStaticFiles();
app.UseCors(CorsPolicy);

app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Migration + seed au boot (hors environnement de tests).
if (!app.Environment.IsEnvironment("Testing"))
{
    using (var scope = app.Services.CreateScope())
    {
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync();
    }

    await DbSeeder.SeedAsync(app.Services);

    // Données de démonstration (« une semaine d'activité ») — activées par défaut en Development,
    // désactivées ailleurs ; surchargeables via Seed:Demo (variable d'env Seed__Demo). Idempotent.
    // Clé absente => défaut selon l'environnement ; clé présente (true/false) => valeur explicite.
    var seedDemoSetting = app.Configuration.GetValue<bool?>($"{SeedOptions.SectionName}:Demo");
    var seedDemo = seedDemoSetting ?? app.Environment.IsDevelopment();
    if (seedDemo)
    {
        await DemoDataSeeder.SeedAsync(app.Services);
    }
}

app.Run();

/// <summary>Point d'entrée exposé pour les tests d'intégration (WebApplicationFactory).</summary>
public partial class Program
{
}
