using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Services;

/// <summary>
/// Upload générique d'images : valide le contenu (allow-list de types + magic bytes) puis délègue au
/// stockage configuré et renvoie l'URL publique.
/// </summary>
public sealed class ImageUploadService : IImageUploadService
{
    private const int HeaderBytes = 16;

    private readonly IImageStorage _storage;

    public ImageUploadService(IImageStorage storage)
    {
        _storage = storage;
    }

    public async Task<UploadResultDto> UploadAsync(Stream content, string fileName, string contentType,
        CancellationToken cancellationToken = default)
    {
        // Bufferise le contenu pour inspecter la signature binaire sans dépendre de la « seekability » de la source.
        using var buffer = new MemoryStream();
        await content.CopyToAsync(buffer, cancellationToken);
        buffer.Position = 0;

        if (buffer.Length == 0)
        {
            throw new ValidationException(ErrorCodes.UploadInvalidFile);
        }

        var headerLength = (int)Math.Min(HeaderBytes, buffer.Length);
        var header = new byte[headerLength];
        _ = buffer.Read(header, 0, headerLength);
        buffer.Position = 0;

        // Allow-list + magic bytes : renvoie le type canonique et l'extension (rejette tout contenu inconnu).
        var (canonicalContentType, canonicalExtension) = ImageFileValidator.Validate(header, contentType);

        // Nom de fichier normalisé à l'extension détectée (ignore l'extension fournie par le client).
        var safeFileName = $"image{canonicalExtension}";

        var url = await _storage.SaveAsync(buffer, safeFileName, canonicalContentType, cancellationToken);
        return new UploadResultDto(url);
    }
}
