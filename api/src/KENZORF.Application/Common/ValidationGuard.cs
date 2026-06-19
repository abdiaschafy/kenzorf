using FluentValidation;
using FluentValidation.Results;

namespace KENZORF.Application.Common;

/// <summary>
/// Exécute un validateur FluentValidation et convertit l'échec en <see cref="ValidationException"/>
/// applicative (format d'erreur du contrat). Les messages des règles sont des clés i18n.
/// </summary>
public static class ValidationGuard
{
    public static async Task EnsureValidAsync<T>(IValidator<T> validator, T instance,
        CancellationToken cancellationToken = default)
    {
        ValidationResult result = await validator.ValidateAsync(instance, cancellationToken);
        if (result.IsValid)
        {
            return;
        }

        var errors = result.Errors
            .GroupBy(e => ToCamelCase(e.PropertyName))
            .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).Distinct().ToArray());

        throw new ValidationException(ErrorCodes.ValidationFailed, errors);
    }

    private static string ToCamelCase(string propertyName)
    {
        if (string.IsNullOrEmpty(propertyName))
        {
            return propertyName;
        }

        // Gère les chemins imbriqués (ex. "ShippingAddress.FullName" -> "shippingAddress.fullName").
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
