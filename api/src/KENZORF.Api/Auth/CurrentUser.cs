using System.Security.Claims;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;

namespace KENZORF.Api.Auth;

/// <summary>Implémentation de <see cref="ICurrentUser"/> à partir des claims du JWT (HttpContext).</summary>
public sealed class CurrentUser : ICurrentUser
{
    private readonly IHttpContextAccessor _accessor;

    public CurrentUser(IHttpContextAccessor accessor)
    {
        _accessor = accessor;
    }

    private ClaimsPrincipal? Principal => _accessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated ?? false;

    public Guid? UserId
    {
        get
        {
            var raw = Principal?.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? Principal?.FindFirstValue("sub");
            return Guid.TryParse(raw, out var id) ? id : null;
        }
    }

    public Guid? CustomerId
    {
        get
        {
            var raw = Principal?.FindFirstValue(AppClaimTypes.CustomerId);
            return Guid.TryParse(raw, out var id) ? id : null;
        }
    }

    public string? Email => Principal?.FindFirstValue(ClaimTypes.Email)
        ?? Principal?.FindFirstValue("email");

    public bool IsAdmin => IsInRole(AppRoles.Admin);

    public bool IsInRole(string role) => Principal?.IsInRole(role) ?? false;
}
