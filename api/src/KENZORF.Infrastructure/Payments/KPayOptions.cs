namespace KENZORF.Infrastructure.Payments;

/// <summary>
/// Configuration KPay (section "KPay"). Vides par défaut → en Development on bascule sur le
/// <c>FakePaymentGateway</c> ; en Production sans clés, l'initiation échoue (fail-closed).
/// </summary>
public sealed class KPayOptions
{
    public const string SectionName = "KPay";

    public string BaseUrl { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public string Secret { get; set; } = string.Empty;
    public string WebhookSecret { get; set; } = string.Empty;

    /// <summary>URL publique de retour après paiement (redirection navigateur / WebView).</summary>
    public string? ReturnUrl { get; set; }

    /// <summary>URL publique du webhook KENZORF transmise au PSP.</summary>
    public string? CallbackUrl { get; set; }

    public bool HasCredentials =>
        !string.IsNullOrWhiteSpace(BaseUrl) &&
        !string.IsNullOrWhiteSpace(ApiKey) &&
        !string.IsNullOrWhiteSpace(Secret);
}
