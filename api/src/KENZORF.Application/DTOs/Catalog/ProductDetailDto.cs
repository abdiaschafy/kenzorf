using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Catalog;

/// <summary>Fiche produit complète : description, catégorie, images et variantes.</summary>
public sealed record ProductDetailDto(
    Guid Id,
    string Name,
    string Slug,
    string Description,
    string? ShortDescription,
    decimal BasePrice,
    decimal? CompareAtPrice,
    string Currency,
    Gender Gender,
    string? Material,
    string? CareInstructions,
    CategoryRefDto Category,
    IReadOnlyList<ImageDto> Images,
    IReadOnlyList<VariantDto> Variants);
