using Microsoft.AspNetCore.Identity;

namespace KENZORF.Infrastructure.Identity;

/// <summary>
/// Compte d'authentification (ASP.NET Core Identity, clé GUID). Lié à un profil <c>Customer</c> du domaine.
/// </summary>
public sealed class ApplicationUser : IdentityUser<Guid>
{
    /// <summary>Identifiant du profil client associé (FK vers Customer).</summary>
    public Guid? CustomerId { get; set; }
}
