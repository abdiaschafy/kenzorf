namespace KENZORF.Application.Common;

/// <summary>
/// Validation des fichiers image uploadés : type MIME en allow-list (jpeg/png/webp/gif), confirmé par les
/// « magic bytes » (signature binaire) du contenu. Renvoie le type canonique et l'extension associée.
/// Rejette tout contenu inconnu ou incohérent (jamais de valeur par défaut silencieuse).
/// </summary>
public static class ImageFileValidator
{
    public const string Jpeg = "image/jpeg";
    public const string Png = "image/png";
    public const string Webp = "image/webp";
    public const string Gif = "image/gif";

    private static readonly HashSet<string> AllowedContentTypes =
        new(StringComparer.OrdinalIgnoreCase) { Jpeg, Png, Webp, Gif };

    /// <summary>
    /// Vérifie l'en-tête <paramref name="header"/> (premiers octets du fichier) et le <paramref name="declaredContentType"/>.
    /// Renvoie le type MIME canonique et l'extension de fichier. Lève <see cref="ValidationException"/> si invalide.
    /// </summary>
    public static (string ContentType, string Extension) Validate(ReadOnlySpan<byte> header, string? declaredContentType)
    {
        // Le type déclaré doit appartenir à l'allow-list (défense en profondeur côté client).
        if (string.IsNullOrWhiteSpace(declaredContentType) || !AllowedContentTypes.Contains(declaredContentType.Trim()))
        {
            throw new ValidationException(ErrorCodes.UploadUnsupportedType);
        }

        // La signature binaire fait foi : elle doit correspondre à un type autorisé.
        var detected = Detect(header);
        if (detected is null)
        {
            throw new ValidationException(ErrorCodes.UploadUnsupportedType);
        }

        return detected.Value;
    }

    private static (string ContentType, string Extension)? Detect(ReadOnlySpan<byte> header)
    {
        // JPEG : FF D8 FF
        if (header.Length >= 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
        {
            return (Jpeg, ".jpg");
        }

        // PNG : 89 50 4E 47 0D 0A 1A 0A
        if (header.Length >= 8 && header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47
            && header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
        {
            return (Png, ".png");
        }

        // GIF : "GIF87a" ou "GIF89a"
        if (header.Length >= 6 && header[0] == (byte)'G' && header[1] == (byte)'I' && header[2] == (byte)'F'
            && header[3] == (byte)'8' && (header[4] == (byte)'7' || header[4] == (byte)'9') && header[5] == (byte)'a')
        {
            return (Gif, ".gif");
        }

        // WEBP : "RIFF" .... "WEBP"
        if (header.Length >= 12 && header[0] == (byte)'R' && header[1] == (byte)'I' && header[2] == (byte)'F'
            && header[3] == (byte)'F' && header[8] == (byte)'W' && header[9] == (byte)'E' && header[10] == (byte)'B'
            && header[11] == (byte)'P')
        {
            return (Webp, ".webp");
        }

        return null;
    }
}
