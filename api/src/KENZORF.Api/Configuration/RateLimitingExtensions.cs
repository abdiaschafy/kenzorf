using System.Text.Json;
using System.Threading.RateLimiting;
using KENZORF.Api.Errors;
using KENZORF.Application.Common;
using Microsoft.AspNetCore.RateLimiting;

namespace KENZORF.Api.Configuration;

/// <summary>
/// Configuration du rate limiting des endpoints sensibles. Limites par adresse IP (fenêtre fixe) sur
/// l'authentification et le webhook de paiement. Désactivé (très généreux) en Development / Testing pour
/// ne pas brider les tests end-to-end. La réponse 429 respecte le format d'erreur du contrat.
/// </summary>
public static class RateLimitingExtensions
{
    /// <summary>Politique de limitation pour /auth/login, /auth/register, /auth/refresh.</summary>
    public const string AuthPolicy = "auth";

    /// <summary>Politique de limitation pour /payments/webhook.</summary>
    public const string WebhookPolicy = "webhook";

    public static IServiceCollection AddKenzorfRateLimiting(this IServiceCollection services, bool relaxed)
    {
        // En Development/Testing : fenêtre courte et plafond très haut => effectivement illimité.
        var authPermit = relaxed ? 100_000 : 10;
        var webhookPermit = relaxed ? 100_000 : 60;

        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            options.AddPolicy(AuthPolicy, httpContext =>
                RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: ResolveClientKey(httpContext),
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = authPermit,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0,
                    }));

            options.AddPolicy(WebhookPolicy, httpContext =>
                RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: ResolveClientKey(httpContext),
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = webhookPermit,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0,
                    }));

            options.OnRejected = async (context, cancellationToken) =>
            {
                var error = new ApiError
                {
                    Code = ErrorCodes.TooManyRequests,
                    MessageKey = ErrorCodes.TooManyRequests,
                    Status = StatusCodes.Status429TooManyRequests,
                };

                context.HttpContext.Response.ContentType = "application/json";
                var payload = JsonSerializer.Serialize(error, new JsonSerializerOptions(JsonSerializerDefaults.Web));
                await context.HttpContext.Response.WriteAsync(payload, cancellationToken);
            };
        });

        return services;
    }

    private static string ResolveClientKey(HttpContext httpContext)
        => httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
}
