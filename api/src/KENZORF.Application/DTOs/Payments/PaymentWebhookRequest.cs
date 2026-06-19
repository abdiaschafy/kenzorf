namespace KENZORF.Application.DTOs.Payments;

/// <summary>
/// Enveloppe brute d'un appel webhook : corps JSON et en-tête de signature.
/// Le parsing/vérification est délégué à la passerelle (<c>IPaymentGateway</c>).
/// </summary>
public sealed record PaymentWebhookRequest(
    string RawBody,
    string? Signature);
