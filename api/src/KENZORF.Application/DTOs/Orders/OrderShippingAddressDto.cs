namespace KENZORF.Application.DTOs.Orders;

/// <summary>Adresse de livraison figée (snapshot) telle qu'enregistrée sur la commande.</summary>
public sealed record OrderShippingAddressDto(
    string FullName,
    string PhoneNumber,
    string Line1,
    string? Line2,
    string City,
    string? Region,
    string Country,
    string? Landmark);
