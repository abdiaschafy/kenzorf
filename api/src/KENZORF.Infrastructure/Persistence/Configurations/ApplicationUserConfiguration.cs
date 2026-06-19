using KENZORF.Domain.Entities;
using KENZORF.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace KENZORF.Infrastructure.Persistence.Configurations;

public sealed class ApplicationUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
{
    public void Configure(EntityTypeBuilder<ApplicationUser> builder)
    {
        builder.Property(u => u.CustomerId);

        builder.HasIndex(u => u.CustomerId).IsUnique().HasFilter(null);

        // Lien optionnel vers le profil Customer ; suppression du compte ne supprime pas le profil.
        builder.HasOne<Customer>()
            .WithMany()
            .HasForeignKey(u => u.CustomerId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
