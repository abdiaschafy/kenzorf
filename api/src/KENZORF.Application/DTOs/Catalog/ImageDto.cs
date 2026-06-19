namespace KENZORF.Application.DTOs.Catalog;

/// <summary>Visuel d'un produit.</summary>
public sealed record ImageDto(
    Guid Id,
    string Url,
    string? AltText,
    bool IsPrimary,
    int DisplayOrder);
