using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Admin;

/// <summary>Création / mise à jour complète d'un produit avec ses images et variantes (back-office).</summary>
public sealed record AdminProductRequest(
    string Name,
    string? Slug,
    string Description,
    string? ShortDescription,
    Guid CategoryId,
    decimal BasePrice,
    decimal? CompareAtPrice,
    Gender Gender,
    string? Material,
    string? CareInstructions,
    bool IsFeatured,
    bool IsActive,
    IReadOnlyList<ProductImageRequest> Images,
    IReadOnlyList<VariantRequest> Variants);
