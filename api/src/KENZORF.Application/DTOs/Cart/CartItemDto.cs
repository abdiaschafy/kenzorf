namespace KENZORF.Application.DTOs.Cart;

/// <summary>Ligne de panier détaillée pour l'affichage côté client.</summary>
public sealed record CartItemDto(
    Guid Id,
    Guid ProductVariantId,
    Guid ProductId,
    string ProductName,
    string ProductSlug,
    string Size,
    string Color,
    string? ColorHex,
    string? ImageUrl,
    decimal UnitPrice,
    int Quantity,
    decimal LineTotal,
    int StockQuantity);
