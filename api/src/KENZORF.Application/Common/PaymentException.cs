namespace KENZORF.Application.Common;

/// <summary>
/// Erreur liée au paiement (HTTP 402) : initiation impossible, passerelle non configurée (fail-closed),
/// signature webhook invalide. Le <c>code</c> porte la clé i18n (ex. "payments.gatewayUnavailable").
/// </summary>
public sealed class PaymentException : AppException
{
    public PaymentException(string code, IReadOnlyDictionary<string, object?>? @params = null)
        : base(code, 402, @params)
    {
    }
}
