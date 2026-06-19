namespace KENZORF.Domain.Enums;

/// <summary>État d'une transaction de paiement (KPay).</summary>
public enum PaymentStatus
{
    Pending = 0,      // Créée, non encore envoyée au PSP
    Initiated = 1,    // Envoyée au PSP, en attente du client
    Succeeded = 2,    // Paiement confirmé
    Failed = 3,       // Échec
    Cancelled = 4,    // Annulé par le client
    Refunded = 5      // Remboursé
}
