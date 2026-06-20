using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class ProductVariantConfiguration : IEntityTypeConfiguration<ProductVariant>
{
    public void Configure(EntityTypeBuilder<ProductVariant> builder)
    {
        builder.ToTable("product_variants");

        builder.HasKey(v => v.Id);

        builder.Property(v => v.Sku).IsRequired().HasMaxLength(64);
        builder.Property(v => v.Size).HasMaxLength(30);
        builder.Property(v => v.Color).IsRequired().HasMaxLength(60);
        builder.Property(v => v.ColorHex).HasMaxLength(9);

        builder.Property(v => v.Price).HasColumnType("decimal(18,2)");

        builder.HasIndex(v => v.Sku).IsUnique();
        builder.HasIndex(v => v.ProductId);
        builder.HasIndex(v => v.IsActive);

        // Garde-fou base : le stock ne peut jamais devenir négatif (le décrément atomique conditionnel
        // s'appuie sur cette invariant — voir PaymentService.HandleWebhookAsync).
        builder.ToTable(t => t.HasCheckConstraint("CK_product_variants_StockQuantity", "\"StockQuantity\" >= 0"));

        // Propriétés calculées non persistées.
        builder.Ignore(v => v.Label);
        builder.Ignore(v => v.InStock);
    }
}
