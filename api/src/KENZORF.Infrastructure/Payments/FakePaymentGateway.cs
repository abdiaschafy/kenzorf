using System.Text.Json;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;
using Microsoft.Extensions.Options;

namespace KENZORF.Infrastructure.Payments;

/// <summary>
/// Passerelle de paiement factice (Development uniquement). Renvoie un <c>checkoutUrl</c> pointant vers
/// une page locale qui permet de simuler le webhook (succès/échec). Ne JAMAIS l'activer en production.
/// </summary>
public sealed class FakePaymentGateway : IPaymentGateway
{
    private readonly KPayOptions _options;

    public FakePaymentGateway(IOptions<KPayOptions> options)
    {
        _options = options.Value;
    }

    public string Provider => "Fake";

    public Task<PaymentInitiationResult> InitiatePaymentAsync(Order order, Payment payment, string? paymentMethod,
        CancellationToken cancellationToken = default)
    {
        var transactionId = $"FAKE-{Guid.NewGuid():N}"[..18].ToUpperInvariant();

        // Page de simulation locale servie par l'API (wwwroot/dev/checkout.html).
        var checkoutUrl =
            $"/dev/checkout.html?reference={Uri.EscapeDataString(payment.Reference)}" +
            $"&amount={payment.Amount}&order={Uri.EscapeDataString(order.OrderNumber)}";

        var result = new PaymentInitiationResult(transactionId, checkoutUrl, PaymentStatus.Initiated);
        return Task.FromResult(result);
    }

    public Task<PaymentWebhookResult?> HandleWebhookAsync(PaymentWebhookRequest request,
        CancellationToken cancellationToken = default)
    {
        // En mode Fake, le "webhook" est déclenché par la page locale ; on accepte tout payload JSON
        // de la forme { "reference": "...", "status": "Succeeded|Failed", "transactionId"?: "..." }.
        if (string.IsNullOrWhiteSpace(request.RawBody))
        {
            return Task.FromResult<PaymentWebhookResult?>(null);
        }

        try
        {
            using var document = JsonDocument.Parse(request.RawBody);
            var root = document.RootElement;

            var reference = root.TryGetProperty("reference", out var refEl) ? refEl.GetString() : null;
            if (string.IsNullOrWhiteSpace(reference))
            {
                return Task.FromResult<PaymentWebhookResult?>(null);
            }

            var statusRaw = root.TryGetProperty("status", out var statusEl) ? statusEl.GetString() : "Succeeded";
            var status = ParseStatus(statusRaw);
            var transactionId = root.TryGetProperty("transactionId", out var txEl) ? txEl.GetString() : null;
            var failureReason = root.TryGetProperty("failureReason", out var frEl) ? frEl.GetString() : null;

            var result = new PaymentWebhookResult(reference!, transactionId, status, failureReason, request.RawBody);
            return Task.FromResult<PaymentWebhookResult?>(result);
        }
        catch (JsonException)
        {
            return Task.FromResult<PaymentWebhookResult?>(null);
        }
    }

    private static PaymentStatus ParseStatus(string? raw)
        => raw?.Trim().ToLowerInvariant() switch
        {
            "failed" or "failure" or "ko" => PaymentStatus.Failed,
            "cancelled" or "canceled" => PaymentStatus.Cancelled,
            _ => PaymentStatus.Succeeded,
        };
}
