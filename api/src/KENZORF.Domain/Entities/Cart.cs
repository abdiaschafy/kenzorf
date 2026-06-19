using KENZORF.Domain.Common;

namespace KENZORF.Domain.Entities;

/// <summary>Panier serveur rattaché à un client connecté.</summary>
public class Cart : AuditableEntity
{
    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    public ICollection<CartItem> Items { get; set; } = new List<CartItem>();

    public decimal Subtotal => Items.Sum(i => i.UnitPrice * i.Quantity);
    public int TotalQuantity => Items.Sum(i => i.Quantity);
}
