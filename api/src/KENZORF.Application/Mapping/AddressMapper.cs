using KENZORF.Application.DTOs.Addresses;
using KENZORF.Domain.Entities;

namespace KENZORF.Application.Mapping;

/// <summary>Projections Domain ↔ DTO pour les adresses.</summary>
public static class AddressMapper
{
    public static AddressDto ToDto(Address address)
        => new(
            address.Id,
            address.Label,
            address.FullName,
            address.PhoneNumber,
            address.Line1,
            address.Line2,
            address.City,
            address.Region,
            address.Country,
            address.Landmark,
            address.IsDefault);

    public static void Apply(Address address, AddressRequest request)
    {
        address.Label = string.IsNullOrWhiteSpace(request.Label) ? "Domicile" : request.Label.Trim();
        address.FullName = request.FullName.Trim();
        address.PhoneNumber = request.PhoneNumber.Trim();
        address.Line1 = request.Line1.Trim();
        address.Line2 = request.Line2?.Trim();
        address.City = request.City.Trim();
        address.Region = request.Region?.Trim();
        address.Country = string.IsNullOrWhiteSpace(request.Country) ? "Côte d'Ivoire" : request.Country.Trim();
        address.Landmark = request.Landmark?.Trim();
    }
}
