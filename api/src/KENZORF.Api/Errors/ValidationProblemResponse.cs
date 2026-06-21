using KENZORF.Application.Common;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Errors;

/// <summary>
/// Fabrique la réponse d'erreur pour les échecs de validation du model binding automatique
/// (<c>[ApiController]</c> / <see cref="ApiBehaviorOptions.InvalidModelStateResponseFactory"/>).
/// Renvoie exactement la même enveloppe que le middleware d'exception pour une
/// <see cref="ValidationException"/> : statut 422, <c>code</c>/<c>messageKey</c> = <c>common.validationFailed</c>,
/// erreurs par champ (clés camelCase). Aucun <c>traceId</c> ni détail interne n'est exposé.
/// </summary>
public static class ValidationProblemResponse
{
    public static IActionResult Create(ActionContext context)
    {
        var errors = context.ModelState
            .Where(entry => entry.Value is { Errors.Count: > 0 })
            .ToDictionary(
                entry => ToCamelCase(entry.Key),
                // Les messages bruts de ModelState sont des phrases UI du framework (.NET, en anglais) :
                // on ne les expose jamais. Chaque champ en échec porte une clé i18n stable.
                _ => new[] { ErrorCodes.ValidationRequired });

        var error = new ApiError
        {
            Code = ErrorCodes.ValidationFailed,
            MessageKey = ErrorCodes.ValidationFailed,
            Status = StatusCodes.Status422UnprocessableEntity,
            Errors = errors.Count > 0 ? errors : null,
        };

        return new ObjectResult(error)
        {
            StatusCode = error.Status,
        };
    }

    /// <summary>Met en camelCase chaque segment du chemin de propriété (ex. "ShippingAddress.FullName").</summary>
    private static string ToCamelCase(string propertyName)
    {
        if (string.IsNullOrEmpty(propertyName))
        {
            return propertyName;
        }

        var segments = propertyName.Split('.');
        for (var i = 0; i < segments.Length; i++)
        {
            var segment = segments[i];
            if (segment.Length > 0 && char.IsUpper(segment[0]))
            {
                segments[i] = char.ToLowerInvariant(segment[0]) + segment[1..];
            }
        }

        return string.Join('.', segments);
    }
}
