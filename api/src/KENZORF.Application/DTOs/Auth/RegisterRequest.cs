namespace KENZORF.Application.DTOs.Auth;

/// <summary>Données d'inscription d'un nouveau client.</summary>
public sealed record RegisterRequest(
    string Email,
    string Password,
    string FirstName,
    string LastName,
    string? PhoneNumber);
