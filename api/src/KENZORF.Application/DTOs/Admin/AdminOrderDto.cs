using KENZORF.Application.DTOs.Orders;
using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Admin;

/// <summary>Commande détaillée pour le back-office (avec coordonnées client).</summary>
public sealed record AdminOrderDto(
    Guid Id,
    string OrderNumber,
    OrderStatus Status,
    Guid CustomerId,
    string CustomerName,
    string CustomerEmail,
    string? CustomerPhone,
    decimal Subtotal,
    decimal ShippingFee,
    decimal Discount,
    decimal Total,
    string Currency,
    IReadOnlyList<OrderItemDto> Items,
    OrderShippingAddressDto ShippingAddress,
    string? CustomerNote,
    string? AdminNote,
    PaymentDto? Payment,
    DateTimeOffset PlacedAt,
    DateTimeOffset? PaidAt,
    DateTimeOffset? ShippedAt,
    DateTimeOffset? DeliveredAt,
    DateTimeOffset? CancelledAt);
