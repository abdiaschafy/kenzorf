namespace KENZORF.Application.DTOs.Cart;

/// <summary>Panier serveur du client connecté.</summary>
public sealed record CartDto(
    Guid Id,
    IReadOnlyList<CartItemDto> Items,
    decimal Subtotal,
    int TotalQuantity,
    string Currency);
