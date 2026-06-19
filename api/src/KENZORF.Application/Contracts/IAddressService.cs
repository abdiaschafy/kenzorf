using KENZORF.Application.DTOs.Addresses;

namespace KENZORF.Application.Contracts;

/// <summary>CRUD des adresses de livraison du client connecté.</summary>
public interface IAddressService
{
    Task<IReadOnlyList<AddressDto>> GetMyAddressesAsync(CancellationToken cancellationToken = default);
    Task<AddressDto> CreateAsync(AddressRequest request, CancellationToken cancellationToken = default);
    Task<AddressDto> UpdateAsync(Guid id, AddressRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
