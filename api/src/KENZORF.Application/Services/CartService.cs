using FluentValidation;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Cart;
using KENZORF.Application.Mapping;
using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Gestion du panier serveur du client connecté.</summary>
public sealed class CartService : ICartService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IValidator<AddCartItemRequest> _addValidator;
    private readonly IValidator<UpdateCartItemRequest> _updateValidator;

    public CartService(
        IAppDbContext db,
        ICurrentUser currentUser,
        IValidator<AddCartItemRequest> addValidator,
        IValidator<UpdateCartItemRequest> updateValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _addValidator = addValidator;
        _updateValidator = updateValidator;
    }

    public async Task<CartDto> GetCartAsync(CancellationToken cancellationToken = default)
    {
        var cart = await GetOrCreateCartAsync(cancellationToken);
        return CartMapper.ToDto(cart);
    }

    public async Task<CartDto> AddItemAsync(AddCartItemRequest request, CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_addValidator, request, cancellationToken);

        var cart = await GetOrCreateCartAsync(cancellationToken);

        var variant = await _db.ProductVariants
            .Include(v => v.Product)
            .FirstOrDefaultAsync(v => v.Id == request.ProductVariantId && v.IsActive, cancellationToken);

        if (variant is null || variant.Product is null || !variant.Product.IsActive)
        {
            throw new NotFoundException(ErrorCodes.ProductVariantNotFound);
        }

        var existing = cart.Items.FirstOrDefault(i => i.ProductVariantId == variant.Id);
        var desiredQuantity = (existing?.Quantity ?? 0) + request.Quantity;

        if (desiredQuantity > variant.StockQuantity)
        {
            throw new ConflictException(ErrorCodes.CartInsufficientStock,
                new Dictionary<string, object?> { ["available"] = variant.StockQuantity });
        }

        var unitPrice = variant.Product.PriceFor(variant);

        if (existing is null)
        {
            var item = new CartItem
            {
                CartId = cart.Id,
                ProductVariantId = variant.Id,
                Quantity = request.Quantity,
                UnitPrice = unitPrice,
            };

            // La clé Guid est ValueGeneratedOnAdd et BaseEntity initialise déjà Id à Guid.NewGuid() :
            // ajouté au seul graphe suivi du panier, EF interpréterait cette clé non-vide comme un
            // enregistrement existant et émettrait un UPDATE (0 ligne -> DbUpdateConcurrencyException).
            // L'ajout explicite via le DbSet force l'état Added -> INSERT.
            _db.CartItems.Add(item);
            cart.Items.Add(item);
        }
        else
        {
            existing.Quantity = desiredQuantity;
            existing.UnitPrice = unitPrice;
        }

        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return await ReloadCartDtoAsync(cart.Id, cancellationToken);
    }

    public async Task<CartDto> UpdateItemAsync(Guid itemId, UpdateCartItemRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_updateValidator, request, cancellationToken);

        var cart = await GetOrCreateCartAsync(cancellationToken);
        var item = cart.Items.FirstOrDefault(i => i.Id == itemId);
        if (item is null)
        {
            throw new NotFoundException(ErrorCodes.CartItemNotFound);
        }

        var variant = await _db.ProductVariants
            .Include(v => v.Product)
            .FirstOrDefaultAsync(v => v.Id == item.ProductVariantId, cancellationToken);

        if (variant is null)
        {
            throw new NotFoundException(ErrorCodes.ProductVariantNotFound);
        }

        if (request.Quantity > variant.StockQuantity)
        {
            throw new ConflictException(ErrorCodes.CartInsufficientStock,
                new Dictionary<string, object?> { ["available"] = variant.StockQuantity });
        }

        item.Quantity = request.Quantity;
        item.UnitPrice = variant.Product.PriceFor(variant);
        cart.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
        return await ReloadCartDtoAsync(cart.Id, cancellationToken);
    }

    public async Task<CartDto> RemoveItemAsync(Guid itemId, CancellationToken cancellationToken = default)
    {
        var cart = await GetOrCreateCartAsync(cancellationToken);
        var item = cart.Items.FirstOrDefault(i => i.Id == itemId);
        if (item is null)
        {
            throw new NotFoundException(ErrorCodes.CartItemNotFound);
        }

        _db.CartItems.Remove(item);
        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return await ReloadCartDtoAsync(cart.Id, cancellationToken);
    }

    public async Task ClearAsync(CancellationToken cancellationToken = default)
    {
        var cart = await GetOrCreateCartAsync(cancellationToken);
        if (cart.Items.Count > 0)
        {
            _db.CartItems.RemoveRange(cart.Items);
            cart.UpdatedAt = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
        }
    }

    private Guid RequireCustomerId()
    {
        if (_currentUser.CustomerId is null)
        {
            throw new UnauthorizedException(ErrorCodes.Unauthorized);
        }

        return _currentUser.CustomerId.Value;
    }

    private async Task<Cart> GetOrCreateCartAsync(CancellationToken cancellationToken)
    {
        var customerId = RequireCustomerId();

        var cart = await _db.Carts
            .Include(c => c.Items)
                .ThenInclude(i => i.ProductVariant)
                    .ThenInclude(v => v.Product)
                        .ThenInclude(p => p.Images)
            .FirstOrDefaultAsync(c => c.CustomerId == customerId, cancellationToken);

        if (cart is not null)
        {
            return cart;
        }

        cart = new Cart { CustomerId = customerId };
        _db.Carts.Add(cart);
        await _db.SaveChangesAsync(cancellationToken);
        return cart;
    }

    private async Task<CartDto> ReloadCartDtoAsync(Guid cartId, CancellationToken cancellationToken)
    {
        var cart = await _db.Carts
            .AsNoTracking()
            .Include(c => c.Items)
                .ThenInclude(i => i.ProductVariant)
                    .ThenInclude(v => v.Product)
                        .ThenInclude(p => p.Images)
            .FirstAsync(c => c.Id == cartId, cancellationToken);

        return CartMapper.ToDto(cart);
    }
}
