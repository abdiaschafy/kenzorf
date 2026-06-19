using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Catalog;

/// <summary>Produit en vue liste / vignette (catalogue, mise en avant).</summary>
public sealed record ProductListItemDto(
    Guid Id,
    string Name,
    string Slug,
    decimal BasePrice,
    decimal? CompareAtPrice,
    string Currency,
    string? PrimaryImageUrl,
    Gender Gender,
    bool InStock,
    bool IsFeatured);
