namespace KENZORF.Application.DTOs.Admin;

/// <summary>Résultat d'un upload d'image : URL accessible publiquement.</summary>
public sealed record UploadResultDto(
    string Url);
