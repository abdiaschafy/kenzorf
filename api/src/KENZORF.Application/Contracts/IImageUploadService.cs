using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Contracts;

/// <summary>Upload générique d'images (back-office) : délègue au stockage et renvoie l'URL publique.</summary>
public interface IImageUploadService
{
    Task<UploadResultDto> UploadAsync(Stream content, string fileName, string contentType,
        CancellationToken cancellationToken = default);
}
