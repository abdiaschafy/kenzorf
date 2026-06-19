using KENZORF.Domain.Common;

namespace KENZORF.Domain.Entities;

/// <summary>Déclinaison vendable d'un produit : couple taille / couleur, stock et SKU propres.</summary>
public class ProductVariant : AuditableEntity
{
    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public string Sku { get; set; } = string.Empty;
    public string Size { get; set; } = string.Empty;     // XS, S, M, L, XL, XXL, 38, 40...
    public string Color { get; set; } = string.Empty;    // Noir, Blanc, Sable...
    public string? ColorHex { get; set; }                // #111111

    /// <summary>Prix spécifique à la variante ; si null on retombe sur Product.BasePrice.</summary>
    public decimal? Price { get; set; }

    public int StockQuantity { get; set; }
    public bool IsActive { get; set; } = true;

    public string Label => string.IsNullOrWhiteSpace(Size) ? Color : $"{Color} / {Size}";
    public bool InStock => StockQuantity > 0;
}
