using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class AddressConfiguration : IEntityTypeConfiguration<Address>
{
    public void Configure(EntityTypeBuilder<Address> builder)
    {
        builder.ToTable("addresses");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.Label).IsRequired().HasMaxLength(60);
        builder.Property(a => a.FullName).IsRequired().HasMaxLength(150);
        builder.Property(a => a.PhoneNumber).IsRequired().HasMaxLength(30);
        builder.Property(a => a.Line1).IsRequired().HasMaxLength(250);
        builder.Property(a => a.Line2).HasMaxLength(250);
        builder.Property(a => a.City).IsRequired().HasMaxLength(120);
        builder.Property(a => a.Region).HasMaxLength(120);
        builder.Property(a => a.Country).IsRequired().HasMaxLength(120);
        builder.Property(a => a.Landmark).HasMaxLength(250);

        builder.HasIndex(a => a.CustomerId);
    }
}
