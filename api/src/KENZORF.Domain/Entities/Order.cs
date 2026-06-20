using KENZORF.Domain.Common;
using KENZORF.Domain.Enums;

namespace KENZORF.Domain.Entities;

/// <summary>Commande passée par un client. Montants en FCFA (XOF).</summary>
public class Order : AuditableEntity
{
    public string OrderNumber { get; set; } = string.Empty;   // ex. KZF-2026-000123

    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    public OrderStatus Status { get; set; } = OrderStatus.Pending;

    public decimal Subtotal { get; set; }
    public decimal ShippingFee { get; set; }
    public decimal Discount { get; set; }
    public decimal Total { get; set; }
    public string Currency { get; set; } = "XOF";

    // Adresse de livraison figée (snapshot au moment de la commande)
    public string ShippingFullName { get; set; } = string.Empty;
    public string ShippingPhone { get; set; } = string.Empty;
    public string ShippingLine1 { get; set; } = string.Empty;
    public string? ShippingLine2 { get; set; }
    public string ShippingCity { get; set; } = string.Empty;
    public string? ShippingRegion { get; set; }
    public string ShippingCountry { get; set; } = "Côte d'Ivoire";
    public string? ShippingLandmark { get; set; }

    public string? CustomerNote { get; set; }

    /// <summary>
    /// Annotation interne back-office (non visible du client). Sert notamment à signaler une commande
    /// nécessitant un traitement manuel — ex. stock insuffisant détecté au moment du paiement (rupture).
    /// </summary>
    public string? AdminNote { get; set; }

    public DateTimeOffset? PaidAt { get; set; }
    public DateTimeOffset? ShippedAt { get; set; }
    public DateTimeOffset? DeliveredAt { get; set; }
    public DateTimeOffset? CancelledAt { get; set; }

    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();

    /// <summary>Recalcule sous-total et total à partir des lignes.</summary>
    public void Recalculate()
    {
        Subtotal = Items.Sum(i => i.LineTotal);
        Total = Subtotal + ShippingFee - Discount;
    }
}
