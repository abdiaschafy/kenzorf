namespace KENZORF.Application.DTOs.Auth;

/// <summary>Requête de rotation du couple de jetons.</summary>
public sealed record RefreshTokenRequest(
    string RefreshToken);
