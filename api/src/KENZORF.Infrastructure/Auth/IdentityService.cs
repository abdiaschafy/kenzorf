using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;

namespace KENZORF.Infrastructure.Auth;

/// <summary>Pont vers ASP.NET Core Identity : création de comptes, validation d'identifiants, rôles.</summary>
public sealed class IdentityService : IIdentityService
{
    private readonly UserManager<ApplicationUser> _userManager;

    public IdentityService(UserManager<ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    public async Task<Guid> CreateCustomerAccountAsync(string email, string password, Guid customerId,
        CancellationToken cancellationToken = default)
    {
        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            EmailConfirmed = true,
            CustomerId = customerId,
        };

        var result = await _userManager.CreateAsync(user, password);
        if (!result.Succeeded)
        {
            throw new Application.Common.ValidationException(
                ErrorCodes.AuthRegistrationFailed,
                new Dictionary<string, string[]>
                {
                    ["password"] = result.Errors.Select(e => $"identity.{e.Code}").ToArray(),
                });
        }

        await _userManager.AddToRoleAsync(user, AppRoles.Customer);
        return user.Id;
    }

    public async Task<(Guid UserId, string Role, Guid? CustomerId)?> ValidateCredentialsAsync(string email,
        string password, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user is null)
        {
            return null;
        }

        if (!await _userManager.CheckPasswordAsync(user, password))
        {
            return null;
        }

        var roles = await _userManager.GetRolesAsync(user);
        var role = roles.Contains(AppRoles.Admin) ? AppRoles.Admin : AppRoles.Customer;
        return (user.Id, role, user.CustomerId);
    }

    public async Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken = default)
        => await _userManager.FindByEmailAsync(email) is not null;

    public async Task<string?> GetRoleAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return null;
        }

        var roles = await _userManager.GetRolesAsync(user);
        return roles.Contains(AppRoles.Admin) ? AppRoles.Admin : AppRoles.Customer;
    }
}
