using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("products");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Name).IsRequired().HasMaxLength(200);
        builder.Property(p => p.Slug).IsRequired().HasMaxLength(220);
        builder.Property(p => p.Description).IsRequired();
        builder.Property(p => p.ShortDescription).HasMaxLength(400);
        builder.Property(p => p.Material).HasMaxLength(200);
        builder.Property(p => p.CareInstructions).HasMaxLength(600);
        builder.Property(p => p.Currency).IsRequired().HasMaxLength(3);

        builder.Property(p => p.BasePrice).HasColumnType("decimal(18,2)");
        builder.Property(p => p.CompareAtPrice).HasColumnType("decimal(18,2)");

        builder.Property(p => p.Gender).HasConversion<string>().HasMaxLength(20);

        builder.HasIndex(p => p.Slug).IsUnique();
        builder.HasIndex(p => p.CategoryId);
        builder.HasIndex(p => p.IsActive);
        builder.HasIndex(p => p.IsFeatured);
        builder.HasIndex(p => p.Gender);

        builder.HasMany(p => p.Images)
            .WithOne(i => i.Product)
            .HasForeignKey(i => i.ProductId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(p => p.Variants)
            .WithOne(v => v.Product)
            .HasForeignKey(v => v.ProductId)
            .OnDelete(DeleteBehavior.Cascade);

        // Propriétés calculées non persistées.
        builder.Ignore(p => p.TotalStock);
    }
}
