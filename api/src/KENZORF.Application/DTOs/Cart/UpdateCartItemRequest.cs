namespace KENZORF.Application.DTOs.Cart;

/// <summary>Mise à jour de la quantité d'une ligne de panier.</summary>
public sealed record UpdateCartItemRequest(
    int Quantity);
