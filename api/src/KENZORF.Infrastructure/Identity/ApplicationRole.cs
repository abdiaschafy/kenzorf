using Microsoft.AspNetCore.Identity;

namespace KENZORF.Infrastructure.Identity;

/// <summary>Rôle Identity (clé GUID). KENZORF n'utilise que "Customer" et "Admin".</summary>
public sealed class ApplicationRole : IdentityRole<Guid>
{
    public ApplicationRole()
    {
    }

    public ApplicationRole(string roleName) : base(roleName)
    {
    }
}
