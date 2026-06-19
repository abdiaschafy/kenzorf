using FluentValidation;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Auth;
using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Implémentation de l'authentification : inscription, connexion, rotation, déconnexion, profil.</summary>
public sealed class AuthService : IAuthService
{
    private readonly IAppDbContext _db;
    private readonly IIdentityService _identity;
    private readonly ITokenService _tokens;
    private readonly ICurrentUser _currentUser;
    private readonly IValidator<RegisterRequest> _registerValidator;
    private readonly IValidator<LoginRequest> _loginValidator;
    private readonly IValidator<RefreshTokenRequest> _refreshValidator;
    private readonly IValidator<LogoutRequest> _logoutValidator;

    public AuthService(
        IAppDbContext db,
        IIdentityService identity,
        ITokenService tokens,
        ICurrentUser currentUser,
        IValidator<RegisterRequest> registerValidator,
        IValidator<LoginRequest> loginValidator,
        IValidator<RefreshTokenRequest> refreshValidator,
        IValidator<LogoutRequest> logoutValidator)
    {
        _db = db;
        _identity = identity;
        _tokens = tokens;
        _currentUser = currentUser;
        _registerValidator = registerValidator;
        _loginValidator = loginValidator;
        _refreshValidator = refreshValidator;
        _logoutValidator = logoutValidator;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_registerValidator, request, cancellationToken);

        var email = request.Email.Trim().ToLowerInvariant();

        if (await _identity.EmailExistsAsync(email, cancellationToken))
        {
            throw new ConflictException(ErrorCodes.AuthEmailAlreadyUsed);
        }

        var customer = new Customer
        {
            Email = email,
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
        };

        _db.Customers.Add(customer);
        await _db.SaveChangesAsync(cancellationToken);

        var userId = await _identity.CreateCustomerAccountAsync(email, request.Password, customer.Id, cancellationToken);

        var tokens = await _tokens.IssueTokensAsync(userId, email, AppRoles.Customer, customer.Id, cancellationToken);

        var user = new UserDto(userId, email, customer.FirstName, customer.LastName, customer.PhoneNumber, AppRoles.Customer);
        return new AuthResponse(tokens.AccessToken, tokens.RefreshToken, tokens.AccessTokenExpiresAt, user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_loginValidator, request, cancellationToken);

        var email = request.Email.Trim().ToLowerInvariant();
        var credentials = await _identity.ValidateCredentialsAsync(email, request.Password, cancellationToken);
        if (credentials is null)
        {
            throw new UnauthorizedException(ErrorCodes.AuthInvalidCredentials);
        }

        var (userId, role, customerId) = credentials.Value;
        var tokens = await _tokens.IssueTokensAsync(userId, email, role, customerId, cancellationToken);

        var user = await BuildUserDtoAsync(userId, email, role, cancellationToken);
        return new AuthResponse(tokens.AccessToken, tokens.RefreshToken, tokens.AccessTokenExpiresAt, user);
    }

    public async Task<AuthResponse> RefreshAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_refreshValidator, request, cancellationToken);

        var rotated = await _tokens.RotateAsync(request.RefreshToken, cancellationToken);
        if (rotated is null)
        {
            throw new UnauthorizedException(ErrorCodes.AuthInvalidRefreshToken);
        }

        var (tokens, userId, email, role) = rotated.Value;
        var user = await BuildUserDtoAsync(userId, email, role, cancellationToken);
        return new AuthResponse(tokens.AccessToken, tokens.RefreshToken, tokens.AccessTokenExpiresAt, user);
    }

    public async Task LogoutAsync(LogoutRequest request, CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_logoutValidator, request, cancellationToken);
        await _tokens.RevokeAsync(request.RefreshToken, cancellationToken);
    }

    public async Task<UserDto> GetCurrentUserAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.IsAuthenticated || _currentUser.UserId is null)
        {
            throw new UnauthorizedException(ErrorCodes.Unauthorized);
        }

        var role = _currentUser.IsAdmin ? AppRoles.Admin : AppRoles.Customer;
        var email = _currentUser.Email ?? string.Empty;
        return await BuildUserDtoAsync(_currentUser.UserId.Value, email, role, cancellationToken);
    }

    private async Task<UserDto> BuildUserDtoAsync(Guid userId, string email, string role,
        CancellationToken cancellationToken)
    {
        // Le profil client est lié par email (l'admin possède aussi un profil Customer dans le seed).
        var customer = await _db.Customers
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Email == email, cancellationToken);

        if (customer is null)
        {
            return new UserDto(userId, email, string.Empty, string.Empty, null, role);
        }

        return new UserDto(userId, email, customer.FirstName, customer.LastName, customer.PhoneNumber, role);
    }
}
