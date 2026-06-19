using System.Globalization;
using System.Text;

namespace KENZORF.Application.Common;

/// <summary>Génère des slugs URL-safe à partir d'un libellé (accents retirés, minuscules, tirets).</summary>
public static class Slugifier
{
    public static string Slugify(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var normalized = value.Trim().ToLowerInvariant().Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder(normalized.Length);

        foreach (var c in normalized)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(c);
            if (category == UnicodeCategory.NonSpacingMark)
            {
                continue;
            }

            if (char.IsLetterOrDigit(c))
            {
                sb.Append(c);
            }
            else if (c is ' ' or '-' or '_' or '/')
            {
                sb.Append('-');
            }
        }

        var slug = sb.ToString().Normalize(NormalizationForm.FormC);

        while (slug.Contains("--"))
        {
            slug = slug.Replace("--", "-");
        }

        return slug.Trim('-');
    }
}
