namespace KENZORF.Application.DTOs.Catalog;

/// <summary>Référence légère vers une catégorie (utilisée dans la fiche produit).</summary>
public sealed record CategoryRefDto(
    Guid Id,
    string Name,
    string Slug);
