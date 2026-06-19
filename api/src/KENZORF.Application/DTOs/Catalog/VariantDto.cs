namespace KENZORF.Application.DTOs.Catalog;

/// <summary>Variante vendable d'un produit (taille / couleur) avec prix effectif et stock.</summary>
public sealed record VariantDto(
    Guid Id,
    string Sku,
    string Size,
    string Color,
    string? ColorHex,
    decimal Price,
    int StockQuantity,
    bool InStock);
