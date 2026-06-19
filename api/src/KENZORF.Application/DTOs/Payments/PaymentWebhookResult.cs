using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Payments;

/// <summary>
/// Données normalisées extraites d'un webhook KPay après vérification de la signature :
/// référence KENZORF, identifiant PSP et statut résultant. Le brut est conservé pour audit.
/// </summary>
public sealed record PaymentWebhookResult(
    string Reference,
    string? ProviderTransactionId,
    PaymentStatus Status,
    string? FailureReason,
    string RawPayload);
