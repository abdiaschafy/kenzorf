namespace KENZORF.Application.DTOs.Admin;

/// <summary>Variante d'un produit en création / mise à jour (back-office).</summary>
public sealed record VariantRequest(
    Guid? Id,
    string Sku,
    string Size,
    string Color,
    string? ColorHex,
    decimal? Price,
    int StockQuantity,
    bool IsActive);
