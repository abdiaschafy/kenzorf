namespace KENZORF.Application.DTOs.Auth;

/// <summary>Identifiants de connexion.</summary>
public sealed record LoginRequest(
    string Email,
    string Password);
