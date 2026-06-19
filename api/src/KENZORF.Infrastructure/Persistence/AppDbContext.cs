using KENZORF.Application.Contracts;
using KENZORF.Domain.Entities;
using KENZORF.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Infrastructure.Persistence;

/// <summary>
/// Contexte EF Core unique de KENZORF : tables Identity (comptes, rôles, refresh tokens) + tables métier.
/// Implémente <see cref="IAppDbContext"/> et <see cref="IUnitOfWork"/> exposés à la couche Application.
/// </summary>
public sealed class AppDbContext
    : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>, IAppDbContext, IUnitOfWork
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductImage> ProductImages => Set<ProductImage>();
    public DbSet<ProductVariant> ProductVariants => Set<ProductVariant>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
