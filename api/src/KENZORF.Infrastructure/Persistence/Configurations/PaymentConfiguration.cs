using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class PaymentConfiguration : IEntityTypeConfiguration<Payment>
{
    public void Configure(EntityTypeBuilder<Payment> builder)
    {
        builder.ToTable("payments");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Provider).IsRequired().HasMaxLength(40);
        builder.Property(p => p.Currency).IsRequired().HasMaxLength(3);
        builder.Property(p => p.Amount).HasColumnType("decimal(18,2)");

        builder.Property(p => p.Status).HasConversion<string>().HasMaxLength(20);

        builder.Property(p => p.Reference).IsRequired().HasMaxLength(64);
        builder.Property(p => p.ProviderTransactionId).HasMaxLength(128);
        builder.Property(p => p.PaymentMethod).HasMaxLength(40);
        builder.Property(p => p.CheckoutUrl).HasMaxLength(1024);
        builder.Property(p => p.FailureReason).HasMaxLength(500);

        // Idempotence du paiement : référence unique (clé d'identité côté PSP).
        builder.HasIndex(p => p.Reference).IsUnique();
        builder.HasIndex(p => p.OrderId);
        builder.HasIndex(p => p.Status);
    }
}
