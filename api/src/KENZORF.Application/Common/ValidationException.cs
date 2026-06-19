namespace KENZORF.Application.Common;

/// <summary>Erreur de validation métier ou d'entrée (HTTP 422). Peut porter le détail par champ.</summary>
public sealed class ValidationException : AppException
{
    /// <summary>Erreurs par champ : nom du champ → liste de clés d'erreur.</summary>
    public IReadOnlyDictionary<string, string[]> Errors { get; }

    public ValidationException(string code, IReadOnlyDictionary<string, string[]>? errors = null,
        IReadOnlyDictionary<string, object?>? @params = null)
        : base(code, 422, @params)
    {
        Errors = errors ?? new Dictionary<string, string[]>();
    }
}
