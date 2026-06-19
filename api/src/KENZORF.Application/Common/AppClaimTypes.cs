namespace KENZORF.Application.Common;

/// <summary>Types de claims spécifiques à KENZORF ajoutés au JWT.</summary>
public static class AppClaimTypes
{
    /// <summary>Identifiant du profil client lié au compte (permet un fail-closed sans accès base).</summary>
    public const string CustomerId = "customerId";
}
