namespace KENZORF.Application.DTOs.Auth;

/// <summary>Requête de révocation d'un refresh token (déconnexion).</summary>
public sealed record LogoutRequest(
    string RefreshToken);
