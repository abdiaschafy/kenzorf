using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class ProductImageConfiguration : IEntityTypeConfiguration<ProductImage>
{
    public void Configure(EntityTypeBuilder<ProductImage> builder)
    {
        builder.ToTable("product_images");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.Url).IsRequired().HasMaxLength(1024);
        builder.Property(i => i.AltText).HasMaxLength(250);

        builder.HasIndex(i => i.ProductId);
    }
}
