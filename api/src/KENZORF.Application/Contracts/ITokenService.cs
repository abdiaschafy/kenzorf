using KENZORF.Application.DTOs.Auth;

namespace KENZORF.Application.Contracts;

/// <summary>
/// Génération et rotation des jetons : access JWT HMAC-SHA256 + refresh opaque hashé en base.
/// </summary>
public interface ITokenService
{
    /// <summary>
    /// Émet un nouveau couple (access + refresh) pour l'utilisateur et persiste le refresh hashé.
    /// Le <paramref name="customerId"/> est ajouté comme claim pour résoudre le profil sans accès base.
    /// </summary>
    Task<TokenPair> IssueTokensAsync(Guid userId, string email, string role, Guid? customerId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Valide le refresh token, révoque l'ancien et émet un nouveau couple (rotation).
    /// Renvoie null si le token est invalide, expiré ou déjà révoqué.
    /// </summary>
    Task<(TokenPair Tokens, Guid UserId, string Email, string Role)?> RotateAsync(string refreshToken,
        CancellationToken cancellationToken = default);

    /// <summary>Révoque un refresh token (déconnexion). Idempotent.</summary>
    Task RevokeAsync(string refreshToken, CancellationToken cancellationToken = default);
}
