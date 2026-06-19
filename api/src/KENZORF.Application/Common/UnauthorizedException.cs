namespace KENZORF.Application.Common;

/// <summary>Authentification requise ou invalide (HTTP 401).</summary>
public sealed class UnauthorizedException : AppException
{
    public UnauthorizedException(string code, IReadOnlyDictionary<string, object?>? @params = null)
        : base(code, 401, @params)
    {
    }
}
