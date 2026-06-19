using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class CartItemConfiguration : IEntityTypeConfiguration<CartItem>
{
    public void Configure(EntityTypeBuilder<CartItem> builder)
    {
        builder.ToTable("cart_items");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.UnitPrice).HasColumnType("decimal(18,2)");

        builder.HasOne(i => i.ProductVariant)
            .WithMany()
            .HasForeignKey(i => i.ProductVariantId)
            .OnDelete(DeleteBehavior.Restrict);

        // Une seule ligne par variante au sein d'un panier.
        builder.HasIndex(i => new { i.CartId, i.ProductVariantId }).IsUnique();

        builder.Ignore(i => i.LineTotal);
    }
}
