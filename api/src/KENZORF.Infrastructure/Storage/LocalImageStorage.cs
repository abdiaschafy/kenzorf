using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace KENZORF.Infrastructure.Storage;

/// <summary>
/// Stockage des images sur disque sous <c>wwwroot/uploads</c> (servies via <c>UseStaticFiles</c>).
/// Renvoie l'URL publique relative (ex. <c>/uploads/2026/06/xxxx.jpg</c>).
/// </summary>
public sealed class LocalImageStorage : IImageStorage
{
    private static readonly HashSet<string> AllowedExtensions =
        new(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".webp", ".gif" };

    private readonly StorageOptions _options;
    private readonly string _rootPath;
    private readonly string _publicPath;

    public LocalImageStorage(IOptions<StorageOptions> options, IHostEnvironment environment)
    {
        _options = options.Value;
        _publicPath = "/" + _options.PublicPath.Trim('/');

        _rootPath = string.IsNullOrWhiteSpace(_options.UploadsPath)
            ? Path.Combine(environment.ContentRootPath, "wwwroot", _options.PublicPath.Trim('/'))
            : _options.UploadsPath;
    }

    public async Task<string> SaveAsync(Stream content, string fileName, string contentType,
        CancellationToken cancellationToken = default)
    {
        var extension = Path.GetExtension(fileName);
        if (string.IsNullOrWhiteSpace(extension) || !AllowedExtensions.Contains(extension))
        {
            // Pas de valeur par défaut silencieuse : on dérive l'extension du type MIME (lui-même validé en
            // amont par ImageUploadService) ; un type inconnu est rejeté.
            extension = ResolveExtension(contentType);
        }

        var now = DateTime.UtcNow;
        var relativeFolder = Path.Combine(now.Year.ToString(), now.Month.ToString("D2"));
        var targetFolder = Path.Combine(_rootPath, relativeFolder);
        Directory.CreateDirectory(targetFolder);

        var safeName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(targetFolder, safeName);

        await using (var fileStream = new FileStream(fullPath, FileMode.Create, FileAccess.Write, FileShare.None))
        {
            await content.CopyToAsync(fileStream, cancellationToken);
        }

        var url = $"{_publicPath}/{now.Year}/{now.Month:D2}/{safeName}";
        return url;
    }

    private static string ResolveExtension(string contentType)
        => contentType.Trim().ToLowerInvariant() switch
        {
            "image/jpeg" => ".jpg",
            "image/png" => ".png",
            "image/webp" => ".webp",
            "image/gif" => ".gif",
            _ => throw new ValidationException(ErrorCodes.UploadUnsupportedType),
        };
}
