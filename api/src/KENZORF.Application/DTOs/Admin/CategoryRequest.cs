namespace KENZORF.Application.DTOs.Admin;

/// <summary>Création / mise à jour d'une catégorie (back-office).</summary>
public sealed record CategoryRequest(
    string Name,
    string? Slug,
    string? Description,
    string? ImageUrl,
    int DisplayOrder,
    bool IsActive);
