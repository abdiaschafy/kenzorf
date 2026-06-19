namespace KENZORF.Application.Common;

/// <summary>Ressource introuvable (HTTP 404). Le <c>code</c> porte la clé i18n (ex. "orders.notFound").</summary>
public sealed class NotFoundException : AppException
{
    public NotFoundException(string code, IReadOnlyDictionary<string, object?>? @params = null)
        : base(code, 404, @params)
    {
    }
}
