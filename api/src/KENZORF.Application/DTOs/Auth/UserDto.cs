namespace KENZORF.Application.DTOs.Auth;

/// <summary>Utilisateur authentifié exposé au client. <c>role</c> vaut "Customer" ou "Admin".</summary>
public sealed record UserDto(
    Guid Id,
    string Email,
    string FirstName,
    string LastName,
    string? PhoneNumber,
    string Role);
