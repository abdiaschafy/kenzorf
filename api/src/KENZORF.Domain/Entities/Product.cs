using KENZORF.Domain.Common;
using KENZORF.Domain.Enums;

namespace KENZORF.Domain.Entities;

/// <summary>Article de la marque KENZORF, décliné en variantes (taille / couleur).</summary>
public class Product : AuditableEntity
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ShortDescription { get; set; }

    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!;

    /// <summary>Prix de référence en FCFA (XOF), valeurs entières.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>Prix barré (avant promo), optionnel.</summary>
    public decimal? CompareAtPrice { get; set; }

    public string Currency { get; set; } = "XOF";

    public Gender Gender { get; set; } = Gender.Unisex;
    public string? Material { get; set; }
    public string? CareInstructions { get; set; }

    public bool IsFeatured { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<ProductImage> Images { get; set; } = new List<ProductImage>();
    public ICollection<ProductVariant> Variants { get; set; } = new List<ProductVariant>();

    public decimal PriceFor(ProductVariant variant) => variant.Price ?? BasePrice;
    public int TotalStock => Variants.Sum(v => v.StockQuantity);
}
