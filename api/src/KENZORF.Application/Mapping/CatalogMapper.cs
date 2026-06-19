using KENZORF.Application.DTOs.Catalog;
using KENZORF.Domain.Entities;

namespace KENZORF.Application.Mapping;

/// <summary>Projections Domain → DTO pour le catalogue.</summary>
public static class CatalogMapper
{
    public static CategoryDto ToDto(Category category, int productCount)
        => new(category.Id, category.Name, category.Slug, category.Description, category.ImageUrl, productCount);

    public static CategoryRefDto ToRef(Category category)
        => new(category.Id, category.Name, category.Slug);

    public static ImageDto ToDto(ProductImage image)
        => new(image.Id, image.Url, image.AltText, image.IsPrimary, image.DisplayOrder);

    public static VariantDto ToDto(ProductVariant variant, decimal effectivePrice)
        => new(variant.Id, variant.Sku, variant.Size, variant.Color, variant.ColorHex,
            effectivePrice, variant.StockQuantity, variant.InStock);

    public static ProductListItemDto ToListItem(Product product)
    {
        var primaryImage = SelectPrimaryImageUrl(product);
        var inStock = product.Variants.Any(v => v.IsActive && v.StockQuantity > 0);
        return new ProductListItemDto(
            product.Id,
            product.Name,
            product.Slug,
            product.BasePrice,
            product.CompareAtPrice,
            product.Currency,
            primaryImage,
            product.Gender,
            inStock,
            product.IsFeatured);
    }

    public static ProductDetailDto ToDetail(Product product)
    {
        var images = product.Images
            .OrderByDescending(i => i.IsPrimary)
            .ThenBy(i => i.DisplayOrder)
            .Select(ToDto)
            .ToList();

        var variants = product.Variants
            .Where(v => v.IsActive)
            .OrderBy(v => v.Size)
            .ThenBy(v => v.Color)
            .Select(v => ToDto(v, product.PriceFor(v)))
            .ToList();

        return new ProductDetailDto(
            product.Id,
            product.Name,
            product.Slug,
            product.Description,
            product.ShortDescription,
            product.BasePrice,
            product.CompareAtPrice,
            product.Currency,
            product.Gender,
            product.Material,
            product.CareInstructions,
            ToRef(product.Category),
            images,
            variants);
    }

    public static string? SelectPrimaryImageUrl(Product product)
        => product.Images
            .OrderByDescending(i => i.IsPrimary)
            .ThenBy(i => i.DisplayOrder)
            .Select(i => i.Url)
            .FirstOrDefault();
}
