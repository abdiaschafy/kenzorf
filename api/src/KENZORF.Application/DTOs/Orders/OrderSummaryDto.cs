using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Orders;

/// <summary>Commande en vue liste (mes commandes).</summary>
public sealed record OrderSummaryDto(
    Guid Id,
    string OrderNumber,
    OrderStatus Status,
    decimal Total,
    string Currency,
    int ItemCount,
    DateTimeOffset PlacedAt);
