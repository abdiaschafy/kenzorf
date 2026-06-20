namespace KENZORF.Infrastructure.Seed;

/// <summary>
/// Configuration de l'amorçage (section "Seed"). <see cref="Demo"/> active le jeu de données de
/// démonstration « une semaine d'activité » (clients, commandes, paiements). Par défaut activé en
/// Development, désactivé ailleurs ; surchargeable via la variable d'environnement <c>Seed__Demo</c>.
/// </summary>
public sealed class SeedOptions
{
    public const string SectionName = "Seed";

    /// <summary>Amorce les données de démonstration en plus du seed de base. Idempotent.</summary>
    public bool Demo { get; set; }
}
