using KENZORF.Application.DTOs.Payments;

namespace KENZORF.Application.Contracts;

/// <summary>Orchestration paiement : polling de statut et traitement idempotent du webhook KPay.</summary>
public interface IPaymentService
{
    /// <summary>Statut courant d'un paiement par sa référence (réservé au propriétaire de la commande).</summary>
    Task<PaymentStatusDto> GetStatusAsync(string reference, CancellationToken cancellationToken = default);

    /// <summary>
    /// Traite un webhook KPay : vérifie la signature, met à jour le paiement et la commande de façon
    /// idempotente (succès → Order Paid, décrément stock, vidage panier). Lève si la signature est invalide.
    /// </summary>
    Task HandleWebhookAsync(PaymentWebhookRequest request, CancellationToken cancellationToken = default);
}
