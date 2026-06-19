using FluentValidation;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Addresses;
using KENZORF.Application.Mapping;
using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>CRUD des adresses de livraison du client connecté (fail-closed sur la propriété).</summary>
public sealed class AddressService : IAddressService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IValidator<AddressRequest> _validator;

    public AddressService(IAppDbContext db, ICurrentUser currentUser, IValidator<AddressRequest> validator)
    {
        _db = db;
        _currentUser = currentUser;
        _validator = validator;
    }

    public async Task<IReadOnlyList<AddressDto>> GetMyAddressesAsync(CancellationToken cancellationToken = default)
    {
        var customerId = RequireCustomerId();

        var addresses = await _db.Addresses
            .AsNoTracking()
            .Where(a => a.CustomerId == customerId)
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

        return addresses.Select(AddressMapper.ToDto).ToList();
    }

    public async Task<AddressDto> CreateAsync(AddressRequest request, CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_validator, request, cancellationToken);
        var customerId = RequireCustomerId();

        var hasAny = await _db.Addresses.AnyAsync(a => a.CustomerId == customerId, cancellationToken);

        var address = new Address
        {
            CustomerId = customerId,
            IsDefault = !hasAny, // la première adresse devient l'adresse par défaut
        };
        AddressMapper.Apply(address, request);

        _db.Addresses.Add(address);
        await _db.SaveChangesAsync(cancellationToken);

        return AddressMapper.ToDto(address);
    }

    public async Task<AddressDto> UpdateAsync(Guid id, AddressRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_validator, request, cancellationToken);
        var customerId = RequireCustomerId();

        var address = await _db.Addresses
            .FirstOrDefaultAsync(a => a.Id == id && a.CustomerId == customerId, cancellationToken);

        if (address is null)
        {
            throw new NotFoundException(ErrorCodes.AddressNotFound);
        }

        AddressMapper.Apply(address, request);
        address.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return AddressMapper.ToDto(address);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var customerId = RequireCustomerId();

        var address = await _db.Addresses
            .FirstOrDefaultAsync(a => a.Id == id && a.CustomerId == customerId, cancellationToken);

        if (address is null)
        {
            throw new NotFoundException(ErrorCodes.AddressNotFound);
        }

        _db.Addresses.Remove(address);
        await _db.SaveChangesAsync(cancellationToken);

        // Réassigne une adresse par défaut s'il en reste.
        if (address.IsDefault)
        {
            var next = await _db.Addresses
                .Where(a => a.CustomerId == customerId)
                .OrderByDescending(a => a.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);

            if (next is not null)
            {
                next.IsDefault = true;
                next.UpdatedAt = DateTimeOffset.UtcNow;
                await _db.SaveChangesAsync(cancellationToken);
            }
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
}
