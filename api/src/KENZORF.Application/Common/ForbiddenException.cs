namespace KENZORF.Application.Common;

/// <summary>Accès refusé : l'utilisateur n'a pas le droit sur cette ressource (HTTP 403).</summary>
public sealed class ForbiddenException : AppException
{
    public ForbiddenException(string code, IReadOnlyDictionary<string, object?>? @params = null)
        : base(code, 403, @params)
    {
    }
}
