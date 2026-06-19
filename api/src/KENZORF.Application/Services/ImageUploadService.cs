using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Services;

/// <summary>Upload générique d'images : délègue au stockage configuré et renvoie l'URL publique.</summary>
public sealed class ImageUploadService : IImageUploadService
{
    private readonly IImageStorage _storage;

    public ImageUploadService(IImageStorage storage)
    {
        _storage = storage;
    }

    public async Task<UploadResultDto> UploadAsync(Stream content, string fileName, string contentType,
        CancellationToken cancellationToken = default)
    {
        var url = await _storage.SaveAsync(content, fileName, contentType, cancellationToken);
        return new UploadResultDto(url);
    }
}
