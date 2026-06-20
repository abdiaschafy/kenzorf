using KENZORF.Application.Contracts;
using KENZORF.Domain.Entities;
using KENZORF.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

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

    public async Task<IAppTransaction> BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        var transaction = await Database.BeginTransactionAsync(cancellationToken);
        return new EfTransaction(transaction);
    }

    /// <summary>Adaptateur exposant une transaction EF Core derrière l'abstraction <see cref="IAppTransaction"/>.</summary>
    private sealed class EfTransaction : IAppTransaction
    {
        private readonly IDbContextTransaction _transaction;

        public EfTransaction(IDbContextTransaction transaction) => _transaction = transaction;

        public Task CommitAsync(CancellationToken cancellationToken = default)
            => _transaction.CommitAsync(cancellationToken);

        public ValueTask DisposeAsync() => _transaction.DisposeAsync();
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        // Les entités KENZORF dérivent de BaseEntity qui assigne `Id = Guid.NewGuid()` à la construction :
        // les clés primaires Guid sont donc fournies par l'application, jamais par la base. Sans cela
        // (ValueGeneratedOnAdd par défaut), ajouter un nouvel enfant à un parent déjà suivi fait
        // interpréter la clé non-vide comme « ligne existante » -> UPDATE (0 ligne) au lieu d'INSERT
        // (cause de la régression panier). On force donc ValueGeneratedNever sur toutes les clés Guid
        // simples. Les clés `int` d'Identity (AspNetUserClaims, AspNetRoleClaims) restent inchangées.
        foreach (var entityType in builder.Model.GetEntityTypes())
        {
            var key = entityType.FindPrimaryKey();
            if (key is { Properties.Count: 1 } && key.Properties[0] is { Name: "Id", ClrType.IsValueType: true } property
                && property.ClrType == typeof(Guid))
            {
                property.ValueGenerated = Microsoft.EntityFrameworkCore.Metadata.ValueGenerated.Never;
            }
        }
    }
}
