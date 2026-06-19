namespace KENZORF.Application.Common;

/// <summary>Génère les numéros de commande et références de paiement uniques de KENZORF.</summary>
public static class ReferenceGenerator
{
    /// <summary>Numéro de commande lisible, ex. KZF-2026-AB12CD34.</summary>
    public static string OrderNumber()
        => $"KZF-{DateTime.UtcNow:yyyy}-{ShortToken()}";

    /// <summary>Référence de paiement unique transmise au PSP, ex. KPY-AB12CD34EF56.</summary>
    public static string PaymentReference()
        => $"KPY-{Guid.NewGuid():N}"[..16].ToUpperInvariant();

    private static string ShortToken()
        => Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
}
