namespace KENZORF.Application.DTOs.Admin;

/// <summary>Image d'un produit fournie dans la requête produit (back-office).</summary>
public sealed record ProductImageRequest(
    string Url,
    string? AltText,
    bool IsPrimary,
    int DisplayOrder);
