namespace KENZORF.Application.Common;

/// <summary>Moyens de paiement KPay acceptés (mobile money + carte).</summary>
public static class PaymentMethods
{
    public const string OrangeMoney = "orange_money";
    public const string Mtn = "mtn";
    public const string Wave = "wave";
    public const string Moov = "moov";
    public const string Card = "card";

    public static readonly string[] All = { OrangeMoney, Mtn, Wave, Moov, Card };

    public static bool IsValid(string? method)
        => method is null || All.Contains(method);
}
