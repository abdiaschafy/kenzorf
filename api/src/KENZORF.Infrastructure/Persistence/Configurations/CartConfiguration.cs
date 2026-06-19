using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class CartConfiguration : IEntityTypeConfiguration<Cart>
{
    public void Configure(EntityTypeBuilder<Cart> builder)
    {
        builder.ToTable("carts");

        builder.HasKey(c => c.Id);

        // Un panier serveur par client.
        builder.HasIndex(c => c.CustomerId).IsUnique();

        builder.HasOne(c => c.Customer)
            .WithMany()
            .HasForeignKey(c => c.CustomerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(c => c.Items)
            .WithOne(i => i.Cart)
            .HasForeignKey(i => i.CartId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Ignore(c => c.Subtotal);
        builder.Ignore(c => c.TotalQuantity);
    }
}
