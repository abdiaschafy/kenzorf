using KENZORF.Domain.Enums;

namespace KENZORF.Infrastructure.Seed;

/// <summary>
/// Jeu de données « une semaine d'activité réelle » KENZORF : clients démo (Abidjan / Afrique de
/// l'Ouest) et plan de répartition des ~30 commandes sur les 7 derniers jours, statuts pondérés.
/// Données statiques uniquement ; la construction des entités est faite par <see cref="DemoDataSeeder"/>.
/// </summary>
internal static class DemoSeedData
{
    public const string Password = "Password123!";

    /// <summary>~8 nouveaux clients démo, emails @kenzorf.com, téléphones +225, 1–2 adresses chacun.</summary>
    public static IReadOnlyList<DemoCustomerSeed> Customers { get; } = new List<DemoCustomerSeed>
    {
        new("Aboubacar", "Traoré", "aboubacar@kenzorf.com", "+2250707112233", new[]
        {
            new DemoAddressSeed("Domicile", "Cocody Angré 7e Tranche, Rue L102", "Abidjan", "Près de la pharmacie Saint Jean"),
            new DemoAddressSeed("Bureau", "Plateau, Avenue Chardy, Imm. Alpha 2000", "Abidjan", "Tour BICICI"),
        }),
        new("Fatoumata", "Bamba", "fatoumata@kenzorf.com", "+2250708223344", new[]
        {
            new DemoAddressSeed("Domicile", "Yopougon Selmer, Carrefour Maroc", "Abidjan", "Face à la station Total"),
        }),
        new("Ismaël", "Koffi", "ismael@kenzorf.com", "+2250709334455", new[]
        {
            new DemoAddressSeed("Domicile", "Marcory Zone 4, Rue du Canal", "Abidjan", "Résidence Les Palmiers"),
            new DemoAddressSeed("Famille", "Treichville Av. 21, Rue 38", "Abidjan", "Marché de Treichville"),
        }),
        new("Mariam", "Ouattara", "mariam@kenzorf.com", "+2250757445566", new[]
        {
            new DemoAddressSeed("Domicile", "Plateau, Bd de la République, Rés. Ivoire", "Abidjan", "Cathédrale Saint-Paul"),
        }),
        new("Yao", "Kouassi", "yao@kenzorf.com", "+2250141556677", new[]
        {
            new DemoAddressSeed("Domicile", "Abobo Baoulé, Rue des Jardins", "Abidjan", "Gare d'Abobo"),
        }),
        new("Aïcha", "Diabaté", "aicha@kenzorf.com", "+2250505667788", new[]
        {
            new DemoAddressSeed("Domicile", "Cocody Riviera Palmeraie, Cité Sir", "Abidjan", "Saint-Viateur"),
            new DemoAddressSeed("Bureau", "Marcory Biétry, Rue des Pêcheurs", "Abidjan", "Zone 4C"),
        }),
        new("Seydou", "Cissé", "seydou@kenzorf.com", "+2250102778899", new[]
        {
            new DemoAddressSeed("Domicile", "Bouaké Belleville, Rue 12", "Bouaké", "Carrefour Belleville"),
        }),
        new("Rokia", "Sanogo", "rokia@kenzorf.com", "+2250748889900", new[]
        {
            new DemoAddressSeed("Domicile", "Treichville Arras 2, Rue 12", "Abidjan", "Stade Houphouët-Boigny"),
        }),
    };

    /// <summary>
    /// Moyens de paiement disponibles (alignés sur les méthodes acceptées par la marketplace).
    /// </summary>
    public static IReadOnlyList<string> PaymentMethods { get; } = new[]
    {
        "orange_money", "mtn", "wave", "moov", "card",
    };

    /// <summary>
    /// Plan des ~30 commandes réparties sur les 7 derniers jours. Statuts pondérés :
    /// Delivered 8, Shipped 5, Processing 4, Paid 4, Pending 5, Cancelled 3, Refunded 1.
    /// Les <c>DaysAgo</c> couvrent J-0 à J-6, les heures restent dans des plages d'achat plausibles.
    /// </summary>
    public static IReadOnlyList<DemoOrderTemplate> OrderPlan { get; } = new List<DemoOrderTemplate>
    {
        // Delivered (8) — les plus anciennes, cycle complet
        new(OrderStatus.Delivered, 6, 9, 14, 2),
        new(OrderStatus.Delivered, 6, 18, 47, 1),
        new(OrderStatus.Delivered, 5, 11, 5, 3),
        new(OrderStatus.Delivered, 5, 20, 33, 2),
        new(OrderStatus.Delivered, 4, 10, 22, 1),
        new(OrderStatus.Delivered, 4, 16, 51, 2),
        new(OrderStatus.Delivered, 3, 13, 8, 3),
        new(OrderStatus.Delivered, 3, 19, 40, 1),

        // Shipped (5)
        new(OrderStatus.Shipped, 3, 8, 18, 2),
        new(OrderStatus.Shipped, 2, 12, 36, 1),
        new(OrderStatus.Shipped, 2, 17, 12, 3),
        new(OrderStatus.Shipped, 2, 21, 5, 2),
        new(OrderStatus.Shipped, 1, 9, 49, 1),

        // Processing (4)
        new(OrderStatus.Processing, 1, 11, 27, 2),
        new(OrderStatus.Processing, 1, 15, 3, 1),
        new(OrderStatus.Processing, 1, 18, 58, 3),
        new(OrderStatus.Processing, 0, 8, 41, 2),

        // Paid (4)
        new(OrderStatus.Paid, 1, 14, 16, 1),
        new(OrderStatus.Paid, 0, 10, 9, 2),
        new(OrderStatus.Paid, 0, 12, 52, 1),
        new(OrderStatus.Paid, 0, 15, 24, 3),

        // Pending (5) — paiement non confirmé
        new(OrderStatus.Pending, 2, 22, 11, 1),
        new(OrderStatus.Pending, 1, 19, 38, 2),
        new(OrderStatus.Pending, 0, 9, 30, 1),
        new(OrderStatus.Pending, 0, 13, 47, 2),
        new(OrderStatus.Pending, 0, 17, 19, 1),

        // Cancelled (3)
        new(OrderStatus.Cancelled, 4, 14, 2, 1),
        new(OrderStatus.Cancelled, 2, 16, 44, 2),
        new(OrderStatus.Cancelled, 0, 11, 13, 1),

        // Refunded (1)
        new(OrderStatus.Refunded, 5, 15, 28, 2),
    };
}
