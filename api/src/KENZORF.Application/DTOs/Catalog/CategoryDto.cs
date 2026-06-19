namespace KENZORF.Application.DTOs.Catalog;

/// <summary>Catégorie du catalogue avec compteur de produits actifs.</summary>
public sealed record CategoryDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    string? ImageUrl,
    int ProductCount);
