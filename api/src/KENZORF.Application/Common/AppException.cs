namespace KENZORF.Application.Common;

/// <summary>
/// Exception applicative de base. Porte un code/clé stable (i18n côté client) et un statut HTTP.
/// Aucune phrase UI : seul le <see cref="Code"/> est destiné au client.
/// </summary>
public abstract class AppException : Exception
{
    /// <summary>Code/clé stable (ex. "orders.notFound") utilisé pour le format d'erreur du contrat.</summary>
    public string Code { get; }

    /// <summary>Statut HTTP associé.</summary>
    public int Status { get; }

    /// <summary>Paramètres optionnels pour l'interpolation i18n côté front.</summary>
    public IReadOnlyDictionary<string, object?> Params { get; }

    protected AppException(string code, int status, IReadOnlyDictionary<string, object?>? @params = null)
        : base(code)
    {
        Code = code;
        Status = status;
        Params = @params ?? new Dictionary<string, object?>();
    }
}
