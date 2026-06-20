using KENZORF.Domain.Enums;

namespace KENZORF.Infrastructure.Seed;

/// <summary>Définition d'une adresse de démonstration (commune d'Abidjan / ville ouest-africaine).</summary>
internal sealed record DemoAddressSeed(
    string Label,
    string Line1,
    string City,
    string? Landmark);

/// <summary>Définition d'un client de démonstration KENZORF (compte + profil + adresses).</summary>
internal sealed record DemoCustomerSeed(
    string FirstName,
    string LastName,
    string Email,
    string PhoneNumber,
    IReadOnlyList<DemoAddressSeed> Addresses);

/// <summary>
/// Gabarit d'une commande de démonstration : statut cible, ancienneté (jours avant aujourd'hui),
/// heure plausible et nombre de lignes. Les variantes et quantités sont tirées au sort par le seeder.
/// </summary>
internal sealed record DemoOrderTemplate(
    OrderStatus Status,
    int DaysAgo,
    int Hour,
    int Minute,
    int LineCount);
