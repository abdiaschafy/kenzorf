using KENZORF.Domain.Common;

namespace KENZORF.Domain.Entities;

/// <summary>Ligne de commande. Les libellés sont figés (snapshot) pour rester stables dans le temps.</summary>
public class OrderItem : BaseEntity
{
    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;

    public Guid? ProductVariantId { get; set; }
    public ProductVariant? ProductVariant { get; set; }

    public string ProductName { get; set; } = string.Empty;
    public string VariantLabel { get; set; } = string.Empty;  // ex. "Noir / M"
    public string Sku { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }

    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }

    public decimal LineTotal => UnitPrice * Quantity;
}
