namespace KENZORF.Application.Common;

/// <summary>
/// Politique de frais de port (MVP) : forfait fixe en FCFA, offert au-delà d'un seuil de sous-total.
/// Montants entiers (XOF).
/// </summary>
public static class ShippingPolicy
{
    public const decimal FlatFee = 2000m;
    public const decimal FreeShippingThreshold = 50000m;

    public static decimal ComputeFee(decimal subtotal)
        => subtotal >= FreeShippingThreshold ? 0m : FlatFee;
}
