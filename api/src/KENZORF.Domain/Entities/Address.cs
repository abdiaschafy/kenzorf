using KENZORF.Domain.Common;

namespace KENZORF.Domain.Entities;

/// <summary>Adresse de livraison d'un client (adaptée au contexte ouest-africain : repère de livraison).</summary>
public class Address : AuditableEntity
{
    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    public string Label { get; set; } = "Domicile";
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Line1 { get; set; } = string.Empty;
    public string? Line2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string? Region { get; set; }
    public string Country { get; set; } = "Côte d'Ivoire";

    /// <summary>Point de repère pour le livreur (quartier, commerce voisin...).</summary>
    public string? Landmark { get; set; }

    public bool IsDefault { get; set; }
}
