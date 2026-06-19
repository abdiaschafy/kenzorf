namespace KENZORF.Application.DTOs.Admin;

/// <summary>Catégorie exposée au back-office (inclut l'état actif et l'ordre d'affichage).</summary>
public sealed record CategoryAdminDto(
    Guid Id,
    string Name,
    string Slug,
    string? Description,
    string? ImageUrl,
    int DisplayOrder,
    bool IsActive,
    int ProductCount);
