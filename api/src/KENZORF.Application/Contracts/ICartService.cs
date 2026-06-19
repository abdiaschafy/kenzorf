using KENZORF.Application.DTOs.Cart;

namespace KENZORF.Application.Contracts;

/// <summary>Gestion du panier serveur du client connecté.</summary>
public interface ICartService
{
    Task<CartDto> GetCartAsync(CancellationToken cancellationToken = default);
    Task<CartDto> AddItemAsync(AddCartItemRequest request, CancellationToken cancellationToken = default);
    Task<CartDto> UpdateItemAsync(Guid itemId, UpdateCartItemRequest request, CancellationToken cancellationToken = default);
    Task<CartDto> RemoveItemAsync(Guid itemId, CancellationToken cancellationToken = default);
    Task ClearAsync(CancellationToken cancellationToken = default);
}
