using KENZORF.Application.Common;
using KENZORF.Application.DTOs.Cart;
using KENZORF.Domain.Entities;

namespace KENZORF.Application.Mapping;

/// <summary>Projections Domain → DTO pour le panier.</summary>
public static class CartMapper
{
    public static CartItemDto ToDto(CartItem item)
    {
        var variant = item.ProductVariant;
        var product = variant.Product;
        var imageUrl = CatalogMapper.SelectPrimaryImageUrl(product);

        return new CartItemDto(
            item.Id,
            item.ProductVariantId,
            product.Id,
            product.Name,
            product.Slug,
            variant.Size,
            variant.Color,
            variant.ColorHex,
            imageUrl,
            item.UnitPrice,
            item.Quantity,
            item.LineTotal,
            variant.StockQuantity);
    }

    public static CartDto ToDto(Cart cart)
    {
        var items = cart.Items
            .OrderBy(i => i.ProductVariant.Product.Name)
            .Select(ToDto)
            .ToList();

        return new CartDto(
            cart.Id,
            items,
            items.Sum(i => i.LineTotal),
            items.Sum(i => i.Quantity),
            Currency.Xof);
    }
}
