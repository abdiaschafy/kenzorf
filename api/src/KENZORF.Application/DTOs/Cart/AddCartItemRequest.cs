namespace KENZORF.Application.DTOs.Cart;

/// <summary>Ajout d'une variante au panier.</summary>
public sealed record AddCartItemRequest(
    Guid ProductVariantId,
    int Quantity);
