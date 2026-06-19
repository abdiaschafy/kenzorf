using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Admin;

/// <summary>Produit en vue liste pour le back-office.</summary>
public sealed record AdminProductSummaryDto(
    Guid Id,
    string Name,
    string Slug,
    string CategoryName,
    decimal BasePrice,
    string Currency,
    Gender Gender,
    int TotalStock,
    int VariantCount,
    bool IsFeatured,
    bool IsActive,
    string? PrimaryImageUrl);
