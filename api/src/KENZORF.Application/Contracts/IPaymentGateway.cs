using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Entities;

namespace KENZORF.Application.Contracts;

/// <summary>
/// Abstraction de la passerelle de paiement (KPay en prod, Fake en dev).
/// Fail-closed : si la passerelle n'est pas configurée, <see cref="InitiatePaymentAsync"/> lève une
/// <c>PaymentException</c> ; on ne simule jamais un succès en production.
/// </summary>
public interface IPaymentGateway
{
    /// <summary>Nom du fournisseur (ex. "KPay", "Fake").</summary>
    string Provider { get; }

    /// <summary>
    /// Initie le paiement d'une commande : renvoie l'URL de checkout et l'identifiant de transaction PSP.
    /// </summary>
    Task<PaymentInitiationResult> InitiatePaymentAsync(Order order, Payment payment, string? paymentMethod,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Vérifie la signature d'un webhook et en extrait les données normalisées.
    /// Renvoie null si la signature est invalide (le webhook doit alors être rejeté).
    /// </summary>
    Task<PaymentWebhookResult?> HandleWebhookAsync(PaymentWebhookRequest request,
        CancellationToken cancellationToken = default);
}
