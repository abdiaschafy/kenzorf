using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("orders");

        builder.HasKey(o => o.Id);

        builder.Property(o => o.OrderNumber).IsRequired().HasMaxLength(40);
        builder.Property(o => o.Currency).IsRequired().HasMaxLength(3);

        builder.Property(o => o.Subtotal).HasColumnType("decimal(18,2)");
        builder.Property(o => o.ShippingFee).HasColumnType("decimal(18,2)");
        builder.Property(o => o.Discount).HasColumnType("decimal(18,2)");
        builder.Property(o => o.Total).HasColumnType("decimal(18,2)");

        builder.Property(o => o.Status).HasConversion<string>().HasMaxLength(20);

        builder.Property(o => o.ShippingFullName).IsRequired().HasMaxLength(150);
        builder.Property(o => o.ShippingPhone).IsRequired().HasMaxLength(30);
        builder.Property(o => o.ShippingLine1).IsRequired().HasMaxLength(250);
        builder.Property(o => o.ShippingLine2).HasMaxLength(250);
        builder.Property(o => o.ShippingCity).IsRequired().HasMaxLength(120);
        builder.Property(o => o.ShippingRegion).HasMaxLength(120);
        builder.Property(o => o.ShippingCountry).IsRequired().HasMaxLength(120);
        builder.Property(o => o.ShippingLandmark).HasMaxLength(250);
        builder.Property(o => o.CustomerNote).HasMaxLength(1000);
        builder.Property(o => o.AdminNote).HasMaxLength(1000);

        builder.HasIndex(o => o.OrderNumber).IsUnique();
        builder.HasIndex(o => o.CustomerId);
        builder.HasIndex(o => o.Status);
        builder.HasIndex(o => o.CreatedAt);

        builder.HasMany(o => o.Items)
            .WithOne(i => i.Order)
            .HasForeignKey(i => i.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(o => o.Payments)
            .WithOne(p => p.Order)
            .HasForeignKey(p => p.OrderId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
