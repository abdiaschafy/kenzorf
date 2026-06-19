using System.Text;
using System.Text.Json.Serialization;
using KENZORF.Api.Auth;
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
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.Key)),
            ClockSkew = TimeSpan.FromSeconds(30),
            RoleClaimType = System.Security.Claims.ClaimTypes.Role,
            NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier,
        };
    });

builder.Services.AddAuthorizationBuilder()
    .AddPolicy(AppRoles.Admin, policy => policy.RequireRole(AppRoles.Admin))
    .AddPolicy(AppRoles.Customer, policy => policy.RequireRole(AppRoles.Customer));

// CORS : back-office Angular (:4200) toujours ; en Development, tout origin pour le mobile.
builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy, policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(_ => true)
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
        else
        {
            policy.WithOrigins("http://localhost:4200")
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
    });
});

var app = builder.Build();

// Pipeline.
app.UseMiddleware<ExceptionHandlingMiddleware>();

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

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Migration + seed au boot (hors environnement de tests).
if (!app.Environment.IsEnvironment("Testing"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
    await DbSeeder.SeedAsync(app.Services);
}

app.Run();

/// <summary>Point d'entrée exposé pour les tests d'intégration (WebApplicationFactory).</summary>
public partial class Program
{
}
