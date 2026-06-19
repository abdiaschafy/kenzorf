namespace KENZORF.Application.DTOs.Addresses;

/// <summary>Données d'une adresse de livraison (création / mise à jour).</summary>
public sealed record AddressRequest(
    string? Label,
    string FullName,
    string PhoneNumber,
    string Line1,
    string? Line2,
    string City,
    string? Region,
    string Country,
    string? Landmark);
