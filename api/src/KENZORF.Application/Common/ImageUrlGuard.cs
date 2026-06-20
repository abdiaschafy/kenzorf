namespace KENZORF.Application.Common;

/// <summary>
/// Validation des URL d'images fournies par le back-office. Accepte soit une URL relative à l'application
/// (ex. <c>/uploads/2026/06/xxx.jpg</c>, produite par notre stockage), soit une URL absolue http(s).
/// Rejette tout schéma dangereux (<c>javascript:</c>, <c>data:</c>, <c>file:</c>...).
/// </summary>
public static class ImageUrlGuard
{
    /// <summary>Valide l'URL et renvoie sa forme normalisée (trim). Lève <see cref="ValidationException"/> si invalide.</summary>
    public static string EnsureValid(string? url)
    {
        var trimmed = (url ?? string.Empty).Trim();

        if (string.IsNullOrEmpty(trimmed))
        {
            throw new ValidationException(ErrorCodes.UploadInvalidFile);
        }

        // URL relative à l'application (upload local servi sous wwwroot) : on l'accepte telle quelle.
        if (trimmed.StartsWith('/') && !trimmed.StartsWith("//", StringComparison.Ordinal))
        {
            return trimmed;
        }

        // Sinon : exiger une URL absolue http(s). Tout autre schéma (javascript, data, file...) est rejeté.
        if (!Uri.TryCreate(trimmed, UriKind.Absolute, out var uri)
            || (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps))
        {
            throw new ValidationException(ErrorCodes.UploadInvalidImageUrl);
        }

        return trimmed;
    }
}
