using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Payments;

/// <summary>
/// Résultat renvoyé par la passerelle (<c>IPaymentGateway</c>) après initiation :
/// identifiant de transaction PSP, URL de redirection et statut résultant.
/// </summary>
public sealed record PaymentInitiationResult(
    string ProviderTransactionId,
    string CheckoutUrl,
    PaymentStatus Status);
