using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Orders;

/// <summary>Commande détaillée (vue client) avec ses lignes, son adresse et son paiement.</summary>
public sealed record OrderDto(
    Guid Id,
    string OrderNumber,
    OrderStatus Status,
    decimal Subtotal,
    decimal ShippingFee,
    decimal Discount,
    decimal Total,
    string Currency,
    IReadOnlyList<OrderItemDto> Items,
    OrderShippingAddressDto ShippingAddress,
    string? CustomerNote,
    PaymentDto? Payment,
    DateTimeOffset PlacedAt,
    DateTimeOffset? PaidAt);
