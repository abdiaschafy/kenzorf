namespace KENZORF.Application.Contracts;

/// <summary>Stockage des images produits. L'implémentation par défaut écrit sous <c>wwwroot/uploads</c>.</summary>
public interface IImageStorage
{
    /// <summary>
    /// Sauvegarde le contenu et renvoie l'URL publique relative (ex. <c>/uploads/xxxx.jpg</c>).
    /// </summary>
    Task<string> SaveAsync(Stream content, string fileName, string contentType,
        CancellationToken cancellationToken = default);
}
