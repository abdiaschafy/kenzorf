namespace KENZORF.Api.Errors;

/// <summary>
/// Format d'erreur unique du contrat KENZORF : <c>{ code, messageKey, params, status }</c>.
/// Jamais de stack trace exposée ; <c>code</c>/<c>messageKey</c> sont des clés i18n.
/// </summary>
public sealed class ApiError
{
    public string Code { get; init; } = string.Empty;
    public string MessageKey { get; init; } = string.Empty;
    public IReadOnlyDictionary<string, object?> Params { get; init; } = new Dictionary<string, object?>();
    public int Status { get; init; }

    /// <summary>Détail des erreurs de validation par champ (présent uniquement en cas de 422).</summary>
    public IReadOnlyDictionary<string, string[]>? Errors { get; init; }
}
