using KENZORF.Domain.Common;

namespace KENZORF.Domain.Entities;

/// <summary>Profil client. Lié à un compte d'authentification (ApplicationUser) côté Infrastructure.</summary>
public class Customer : AuditableEntity
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }

    public ICollection<Address> Addresses { get; set; } = new List<Address>();
    public ICollection<Order> Orders { get; set; } = new List<Order>();

    public string FullName => $"{FirstName} {LastName}".Trim();
}
