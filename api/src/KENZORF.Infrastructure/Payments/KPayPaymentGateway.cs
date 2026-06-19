using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace KENZORF.Infrastructure.Payments;

/// <summary>
/// Adapter KPay (kpay.site) — pattern agrégateur mobile-money / carte.
/// L'API publique exacte n'étant pas documentée, l'initiation envoie un payload signé HMAC-SHA256 et le
/// webhook est vérifié via la même signature (en-tête X-KPay-Signature). <b>Fail-closed</b> : sans clés
/// valides, <see cref="InitiatePaymentAsync"/> lève une <see cref="PaymentException"/>.
/// </summary>
public sealed class KPayPaymentGateway : IPaymentGateway
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly HttpClient _httpClient;
    private readonly KPayOptions _options;
    private readonly ILogger<KPayPaymentGateway> _logger;

    public KPayPaymentGateway(HttpClient httpClient, IOptions<KPayOptions> options,
        ILogger<KPayPaymentGateway> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public string Provider => "KPay";

    public async Task<PaymentInitiationResult> InitiatePaymentAsync(Order order, Payment payment,
        string? paymentMethod, CancellationToken cancellationToken = default)
    {
        // Fail-closed : on refuse plutôt que de simuler un succès si la passerelle n'est pas configurée.
        if (!_options.HasCredentials)
        {
            _logger.LogError("KPay credentials are missing; refusing to initiate payment {Reference}.",
                payment.Reference);
            throw new PaymentException(ErrorCodes.PaymentGatewayUnavailable);
        }

        var body = new
        {
            reference = payment.Reference,
            amount = (long)payment.Amount,
            currency = payment.Currency,
            orderNumber = order.OrderNumber,
            paymentMethod,
            customerName = order.ShippingFullName,
            customerPhone = order.ShippingPhone,
            returnUrl = _options.ReturnUrl,
            callbackUrl = _options.CallbackUrl,
        };

        var json = JsonSerializer.Serialize(body, JsonOptions);
        var signature = ComputeSignature(json);

        using var requestMessage = new HttpRequestMessage(HttpMethod.Post, "payments/initiate")
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json"),
        };
        requestMessage.Headers.TryAddWithoutValidation("X-API-Key", _options.ApiKey);
        requestMessage.Headers.TryAddWithoutValidation("X-KPay-Signature", signature);

        try
        {
            using var response = await _httpClient.SendAsync(requestMessage, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("KPay initiation failed for {Reference} with status {Status}.",
                    payment.Reference, (int)response.StatusCode);
                throw new PaymentException(ErrorCodes.PaymentInitiationFailed);
            }

            var payload = await response.Content.ReadFromJsonAsync<KPayInitiationResponse>(JsonOptions,
                cancellationToken);

            if (payload is null || string.IsNullOrWhiteSpace(payload.CheckoutUrl))
            {
                throw new PaymentException(ErrorCodes.PaymentInitiationFailed);
            }

            return new PaymentInitiationResult(
                payload.TransactionId ?? payment.Reference,
                payload.CheckoutUrl!,
                PaymentStatus.Initiated);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "KPay initiation transport error for {Reference}.", payment.Reference);
            throw new PaymentException(ErrorCodes.PaymentInitiationFailed);
        }
    }

    public Task<PaymentWebhookResult?> HandleWebhookAsync(PaymentWebhookRequest request,
        CancellationToken cancellationToken = default)
    {
        // Fail-closed : sans secret de webhook configuré, on rejette.
        if (string.IsNullOrWhiteSpace(_options.WebhookSecret) || string.IsNullOrWhiteSpace(request.RawBody))
        {
            return Task.FromResult<PaymentWebhookResult?>(null);
        }

        var expected = ComputeSignature(request.RawBody, _options.WebhookSecret);
        if (string.IsNullOrWhiteSpace(request.Signature) || !FixedTimeEquals(expected, request.Signature))
        {
            _logger.LogWarning("KPay webhook signature mismatch.");
            return Task.FromResult<PaymentWebhookResult?>(null);
        }

        try
        {
            var payload = JsonSerializer.Deserialize<KPayWebhookPayload>(request.RawBody, JsonOptions);
            if (payload is null || string.IsNullOrWhiteSpace(payload.Reference))
            {
                return Task.FromResult<PaymentWebhookResult?>(null);
            }

            var status = MapStatus(payload.Status);
            var result = new PaymentWebhookResult(
                payload.Reference!,
                payload.TransactionId,
                status,
                payload.FailureReason,
                request.RawBody);

            return Task.FromResult<PaymentWebhookResult?>(result);
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "KPay webhook payload could not be parsed.");
            return Task.FromResult<PaymentWebhookResult?>(null);
        }
    }

    private string ComputeSignature(string payload) => ComputeSignature(payload, _options.Secret);

    private static string ComputeSignature(string payload, string secret)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    private static bool FixedTimeEquals(string a, string b)
    {
        var ba = Encoding.UTF8.GetBytes(a);
        var bb = Encoding.UTF8.GetBytes(b);
        return ba.Length == bb.Length && CryptographicOperations.FixedTimeEquals(ba, bb);
    }

    private static PaymentStatus MapStatus(string? raw)
        => raw?.Trim().ToLowerInvariant() switch
        {
            "success" or "succeeded" or "paid" or "completed" => PaymentStatus.Succeeded,
            "failed" or "failure" or "declined" => PaymentStatus.Failed,
            "cancelled" or "canceled" => PaymentStatus.Cancelled,
            "refunded" => PaymentStatus.Refunded,
            _ => PaymentStatus.Initiated,
        };

    private sealed record KPayInitiationResponse(string? TransactionId, string? CheckoutUrl);

    private sealed record KPayWebhookPayload(
        string? Reference,
        string? TransactionId,
        string? Status,
        string? FailureReason);
}
