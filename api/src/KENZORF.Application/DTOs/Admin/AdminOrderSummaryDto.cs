using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Admin;

/// <summary>Commande en vue liste pour le back-office.</summary>
public sealed record AdminOrderSummaryDto(
    Guid Id,
    string OrderNumber,
    OrderStatus Status,
    string CustomerName,
    string CustomerEmail,
    decimal Total,
    string Currency,
    int ItemCount,
    DateTimeOffset PlacedAt);
