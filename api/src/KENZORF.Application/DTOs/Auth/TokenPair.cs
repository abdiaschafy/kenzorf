namespace KENZORF.Application.DTOs.Auth;

/// <summary>Résultat brut de génération de jetons par <c>ITokenService</c> (interne Application/Infrastructure).</summary>
public sealed record TokenPair(
    string AccessToken,
    string RefreshToken,
    DateTimeOffset AccessTokenExpiresAt);
