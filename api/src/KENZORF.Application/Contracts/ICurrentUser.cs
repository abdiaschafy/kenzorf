namespace KENZORF.Application.Contracts;

/// <summary>
/// Accès à l'utilisateur authentifié pour la requête courante (implémenté côté Api via HttpContext).
/// Mono-tenant : pas de TenantId, on expose uniquement l'identité et le profil client lié.
/// </summary>
public interface ICurrentUser
{
    bool IsAuthenticated { get; }

    /// <summary>Identifiant du compte d'authentification (ApplicationUser).</summary>
    Guid? UserId { get; }

    /// <summary>Identifiant du profil client lié, si l'utilisateur en possède un.</summary>
    Guid? CustomerId { get; }

    string? Email { get; }

    bool IsAdmin { get; }

    bool IsInRole(string role);
}
