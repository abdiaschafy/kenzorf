using KENZORF.Application.DTOs.Auth;

namespace KENZORF.Application.Contracts;

/// <summary>
/// Pont vers ASP.NET Core Identity (Infrastructure). Permet à l'<c>AuthService</c> applicatif de créer
/// des comptes et de valider des identifiants sans dépendre directement d'Identity.
/// </summary>
public interface IIdentityService
{
    /// <summary>
    /// Crée un compte (rôle Customer) lié au profil client fourni. Renvoie l'identifiant du compte créé.
    /// </summary>
    Task<Guid> CreateCustomerAccountAsync(string email, string password, Guid customerId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Vérifie les identifiants ; renvoie (userId, role, customerId) en cas de succès, null sinon.
    /// </summary>
    Task<(Guid UserId, string Role, Guid? CustomerId)?> ValidateCredentialsAsync(string email, string password,
        CancellationToken cancellationToken = default);

    /// <summary>Indique si un compte existe déjà pour cet email.</summary>
    Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken = default);

    /// <summary>Récupère le rôle principal d'un compte.</summary>
    Task<string?> GetRoleAsync(Guid userId, CancellationToken cancellationToken = default);
}
