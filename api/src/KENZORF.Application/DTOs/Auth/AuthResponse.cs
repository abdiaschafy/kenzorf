namespace KENZORF.Application.DTOs.Auth;

/// <summary>Réponse d'authentification : couple de jetons + profil utilisateur.</summary>
public sealed record AuthResponse(
    string AccessToken,
    string RefreshToken,
    DateTimeOffset ExpiresAt,
    UserDto User);
