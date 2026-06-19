using KENZORF.Application.DTOs.Orders;
using KENZORF.Domain.Entities;

namespace KENZORF.Application.Mapping;

/// <summary>Projections Domain → DTO pour les commandes (vue client).</summary>
public static class OrderMapper
{
    public static OrderItemDto ToDto(OrderItem item)
        => new(
            item.Id,
            item.ProductName,
            item.VariantLabel,
            item.Sku,
            item.ImageUrl,
            item.UnitPrice,
            item.Quantity,
            item.LineTotal);

    public static OrderShippingAddressDto ToShippingAddress(Order order)
        => new(
            order.ShippingFullName,
            order.ShippingPhone,
            order.ShippingLine1,
            order.ShippingLine2,
            order.ShippingCity,
            order.ShippingRegion,
            order.ShippingCountry,
            order.ShippingLandmark);

    public static OrderDto ToDto(Order order)
    {
        var latestPayment = order.Payments
            .OrderByDescending(p => p.CreatedAt)
            .FirstOrDefault();

        return new OrderDto(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.Subtotal,
            order.ShippingFee,
            order.Discount,
            order.Total,
            order.Currency,
            order.Items.Select(ToDto).ToList(),
            ToShippingAddress(order),
            order.CustomerNote,
            latestPayment is null ? null : PaymentMapper.ToDto(latestPayment),
            order.CreatedAt,
            order.PaidAt);
    }

    public static OrderSummaryDto ToSummary(Order order)
        => new(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.Total,
            order.Currency,
            order.Items.Sum(i => i.Quantity),
            order.CreatedAt);
}
