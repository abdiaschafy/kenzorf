using KENZORF.Application.DTOs.Catalog;
using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Admin;

/// <summary>Produit complet exposé au back-office (inclut variantes inactives et stock).</summary>
public sealed record AdminProductDto(
    Guid Id,
    string Name,
    string Slug,
    string Description,
    string? ShortDescription,
    CategoryRefDto Category,
    decimal BasePrice,
    decimal? CompareAtPrice,
    string Currency,
    Gender Gender,
    string? Material,
    string? CareInstructions,
    bool IsFeatured,
    bool IsActive,
    int TotalStock,
    IReadOnlyList<ImageDto> Images,
    IReadOnlyList<AdminVariantDto> Variants,
    DateTimeOffset CreatedAt,
    DateTimeOffset? UpdatedAt);
