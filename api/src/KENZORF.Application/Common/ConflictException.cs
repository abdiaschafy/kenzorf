namespace KENZORF.Application.Common;

/// <summary>Conflit d'état (HTTP 409) : transition invalide, doublon, ressource déjà dans cet état.</summary>
public sealed class ConflictException : AppException
{
    public ConflictException(string code, IReadOnlyDictionary<string, object?>? @params = null)
        : base(code, 409, @params)
    {
    }
}
