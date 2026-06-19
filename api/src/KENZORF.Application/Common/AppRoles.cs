namespace KENZORF.Application.Common;

/// <summary>Les deux seuls rôles de KENZORF (mono-tenant, pas de RBAC d'agence).</summary>
public static class AppRoles
{
    public const string Customer = "Customer";
    public const string Admin = "Admin";

    public static readonly string[] All = { Customer, Admin };
}
