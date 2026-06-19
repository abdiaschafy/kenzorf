using KENZORF.Domain.Common;
using KENZORF.Domain.Enums;

namespace KENZORF.Domain.Entities;

/// <summary>Transaction de paiement rattachée à une commande (fournisseur KPay par défaut).</summary>
public class Payment : AuditableEntity
{
    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;

    public string Provider { get; set; } = "KPay";
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "XOF";
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;

    /// <summary>Référence unique générée côté KENZORF et transmise au PSP.</summary>
    public string Reference { get; set; } = string.Empty;

    /// <summary>Identifiant de transaction renvoyé par KPay.</summary>
    public string? ProviderTransactionId { get; set; }

    /// <summary>Moyen utilisé (Orange Money, MTN, Wave, carte...).</summary>
    public string? PaymentMethod { get; set; }

    /// <summary>URL de redirection vers la page de paiement KPay.</summary>
    public string? CheckoutUrl { get; set; }

    public string? FailureReason { get; set; }

    /// <summary>Charge utile brute du callback, conservée pour audit.</summary>
    public string? RawPayload { get; set; }

    public DateTimeOffset? CompletedAt { get; set; }
}
