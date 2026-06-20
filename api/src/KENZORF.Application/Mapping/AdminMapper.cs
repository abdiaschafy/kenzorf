using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Catalog;
using KENZORF.Application.DTOs.Orders;
using KENZORF.Domain.Entities;

namespace KENZORF.Application.Mapping;

/// <summary>Projections Domain → DTO pour le back-office.</summary>
public static class AdminMapper
{
    public static AdminVariantDto ToDto(ProductVariant variant, decimal effectivePrice)
        => new(
            variant.Id,
            variant.Sku,
            variant.Size,
            variant.Color,
            variant.ColorHex,
            variant.Price,
            effectivePrice,
            variant.StockQuantity,
            variant.IsActive);

    public static AdminProductDto ToDto(Product product)
    {
        var images = product.Images
            .OrderByDescending(i => i.IsPrimary)
            .ThenBy(i => i.DisplayOrder)
            .Select(CatalogMapper.ToDto)
            .ToList();

        var variants = product.Variants
            .OrderBy(v => v.Size)
            .ThenBy(v => v.Color)
            .Select(v => ToDto(v, product.PriceFor(v)))
            .ToList();

        return new AdminProductDto(
            product.Id,
            product.Name,
            product.Slug,
            product.Description,
            product.ShortDescription,
            CatalogMapper.ToRef(product.Category),
            product.BasePrice,
            product.CompareAtPrice,
            product.Currency,
            product.Gender,
            product.Material,
            product.CareInstructions,
            product.IsFeatured,
            product.IsActive,
            product.Variants.Sum(v => v.StockQuantity),
            images,
            variants,
            product.CreatedAt,
            product.UpdatedAt);
    }

    public static AdminProductSummaryDto ToSummary(Product product)
        => new(
            product.Id,
            product.Name,
            product.Slug,
            product.Category?.Name ?? string.Empty,
            product.BasePrice,
            product.Currency,
            product.Gender,
            product.Variants.Sum(v => v.StockQuantity),
            product.Variants.Count,
            product.IsFeatured,
            product.IsActive,
            CatalogMapper.SelectPrimaryImageUrl(product));

    public static CategoryAdminDto ToAdminDto(Category category, int productCount)
        => new(
            category.Id,
            category.Name,
            category.Slug,
            category.Description,
            category.ImageUrl,
            category.DisplayOrder,
            category.IsActive,
            productCount);

    public static AdminOrderSummaryDto ToSummary(Order order)
        => new(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.Customer?.FullName ?? order.ShippingFullName,
            order.Customer?.Email ?? string.Empty,
            order.Total,
            order.Currency,
            order.Items.Sum(i => i.Quantity),
            order.CreatedAt);

    public static AdminOrderDto ToDto(Order order)
    {
        var latestPayment = order.Payments
            .OrderByDescending(p => p.CreatedAt)
            .FirstOrDefault();

        return new AdminOrderDto(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.CustomerId,
            order.Customer?.FullName ?? order.ShippingFullName,
            order.Customer?.Email ?? string.Empty,
            order.Customer?.PhoneNumber,
            order.Subtotal,
            order.ShippingFee,
            order.Discount,
            order.Total,
            order.Currency,
            order.Items.Select(OrderMapper.ToDto).ToList(),
            OrderMapper.ToShippingAddress(order),
            order.CustomerNote,
            order.AdminNote,
            latestPayment is null ? null : PaymentMapper.ToDto(latestPayment),
            order.CreatedAt,
            order.PaidAt,
            order.ShippedAt,
            order.DeliveredAt,
            order.CancelledAt);
    }

    public static CustomerDto ToDto(Customer customer, int orderCount, decimal totalSpent, string currency)
        => new(
            customer.Id,
            customer.FirstName,
            customer.LastName,
            customer.Email,
            customer.PhoneNumber,
            orderCount,
            totalSpent,
            currency,
            customer.CreatedAt);

    public static LowStockVariantDto ToLowStock(ProductVariant variant)
        => new(
            variant.Id,
            variant.ProductId,
            variant.Product?.Name ?? string.Empty,
            variant.Sku,
            variant.Label,
            variant.StockQuantity);
}
