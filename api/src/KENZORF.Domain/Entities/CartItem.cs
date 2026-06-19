using KENZORF.Domain.Common;

namespace KENZORF.Domain.Entities;

/// <summary>Ligne de panier : une variante produit et sa quantité.</summary>
public class CartItem : BaseEntity
{
    public Guid CartId { get; set; }
    public Cart Cart { get; set; } = null!;

    public Guid ProductVariantId { get; set; }
    public ProductVariant ProductVariant { get; set; } = null!;

    public int Quantity { get; set; }

    /// <summary>Prix figé au moment de l'ajout (en FCFA).</summary>
    public decimal UnitPrice { get; set; }

    public decimal LineTotal => UnitPrice * Quantity;
}
