using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Contracts;

/// <summary>
/// Surface du contexte de données exposée à la couche Application (sans dépendre de l'implémentation EF
/// concrète ni d'Identity). Les services écrivent leurs requêtes LINQ contre ces ensembles.
/// </summary>
public interface IAppDbContext
{
    DbSet<Category> Categories { get; }
    DbSet<Product> Products { get; }
    DbSet<ProductImage> ProductImages { get; }
    DbSet<ProductVariant> ProductVariants { get; }
    DbSet<Customer> Customers { get; }
    DbSet<Address> Addresses { get; }
    DbSet<Cart> Carts { get; }
    DbSet<CartItem> CartItems { get; }
    DbSet<Order> Orders { get; }
    DbSet<OrderItem> OrderItems { get; }
    DbSet<Payment> Payments { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
