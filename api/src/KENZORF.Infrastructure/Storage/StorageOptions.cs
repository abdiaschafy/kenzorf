namespace KENZORF.Infrastructure.Storage;

/// <summary>Configuration du stockage local des images (section "Storage").</summary>
public sealed class StorageOptions
{
    public const string SectionName = "Storage";

    /// <summary>Chemin physique racine des uploads. Par défaut <c>wwwroot/uploads</c> (résolu au runtime).</summary>
    public string? UploadsPath { get; set; }

    /// <summary>Préfixe d'URL publique servant les fichiers.</summary>
    public string PublicPath { get; set; } = "/uploads";
}
