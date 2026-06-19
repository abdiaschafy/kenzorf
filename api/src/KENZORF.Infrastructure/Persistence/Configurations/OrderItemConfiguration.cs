using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.ToTable("order_items");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.ProductName).IsRequired().HasMaxLength(200);
        builder.Property(i => i.VariantLabel).IsRequired().HasMaxLength(120);
        builder.Property(i => i.Sku).IsRequired().HasMaxLength(64);
        builder.Property(i => i.ImageUrl).HasMaxLength(1024);

        builder.Property(i => i.UnitPrice).HasColumnType("decimal(18,2)");

        builder.HasIndex(i => i.OrderId);

        // La variante peut être supprimée du catalogue : on garde la ligne (snapshot), FK nullable.
        builder.HasOne(i => i.ProductVariant)
            .WithMany()
            .HasForeignKey(i => i.ProductVariantId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.Ignore(i => i.LineTotal);
    }
}
