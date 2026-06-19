namespace KENZORF.Domain.Enums;

/// <summary>Cycle de vie d'une commande KENZORF.</summary>
public enum OrderStatus
{
    Pending = 0,      // En attente de paiement
    Paid = 1,         // Payée
    Processing = 2,   // En préparation
    Shipped = 3,      // Expédiée
    Delivered = 4,    // Livrée
    Cancelled = 5,    // Annulée
    Refunded = 6      // Remboursée
}
