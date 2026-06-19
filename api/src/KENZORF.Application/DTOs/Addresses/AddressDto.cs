namespace KENZORF.Application.DTOs.Addresses;

/// <summary>Adresse de livraison d'un client.</summary>
public sealed record AddressDto(
    Guid Id,
    string Label,
    string FullName,
    string PhoneNumber,
    string Line1,
    string? Line2,
    string City,
    string? Region,
    string Country,
    string? Landmark,
    bool IsDefault);
