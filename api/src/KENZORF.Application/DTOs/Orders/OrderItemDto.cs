namespace KENZORF.Application.DTOs.Orders;

/// <summary>Ligne de commande (libellés figés).</summary>
public sealed record OrderItemDto(
    Guid Id,
    string ProductName,
    string VariantLabel,
    string Sku,
    string? ImageUrl,
    decimal UnitPrice,
    int Quantity,
    decimal LineTotal);
