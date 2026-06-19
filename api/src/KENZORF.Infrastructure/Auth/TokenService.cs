using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Auth;
using KENZORF.Infrastructure.Identity;
using KENZORF.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace KENZORF.Infrastructure.Auth;

/// <summary>
/// Émission et rotation des jetons. Access = JWT HMAC-SHA256 (claims sub/email/role).
/// Refresh = secret opaque aléatoire, stocké uniquement sous forme de hash SHA-256 ; rotation à chaque usage.
/// </summary>
public sealed class TokenService : ITokenService
{
    private readonly AppDbContext _db;
    private readonly JwtOptions _options;

    public TokenService(AppDbContext db, IOptions<JwtOptions> options)
    {
        _db = db;
        _options = options.Value;
    }

    public async Task<TokenPair> IssueTokensAsync(Guid userId, string email, string role, Guid? customerId,
        CancellationToken cancellationToken = default)
    {
        var (accessToken, expiresAt) = CreateAccessToken(userId, email, role, customerId);
        var refreshToken = await CreateRefreshTokenAsync(userId, cancellationToken);
        return new TokenPair(accessToken, refreshToken, expiresAt);
    }

    public async Task<(TokenPair Tokens, Guid UserId, string Email, string Role)?> RotateAsync(string refreshToken,
        CancellationToken cancellationToken = default)
    {
        var hash = Hash(refreshToken);

        var stored = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.TokenHash == hash, cancellationToken);

        if (stored is null || !stored.IsActive)
        {
            return null;
        }

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == stored.UserId, cancellationToken);
        if (user is null)
        {
            return null;
        }

        var roles = await _db.UserRoles.Where(ur => ur.UserId == user.Id).ToListAsync(cancellationToken);
        var roleIds = roles.Select(r => r.RoleId).ToList();
        var roleNames = await _db.Roles
            .Where(r => roleIds.Contains(r.Id))
            .Select(r => r.Name!)
            .ToListAsync(cancellationToken);
        var role = roleNames.Contains(Application.Common.AppRoles.Admin)
            ? Application.Common.AppRoles.Admin
            : Application.Common.AppRoles.Customer;

        var email = user.Email ?? string.Empty;

        // Rotation : révoque l'ancien et émet un nouveau couple.
        var (accessToken, expiresAt) = CreateAccessToken(user.Id, email, role, user.CustomerId);
        var newRefresh = await CreateRefreshTokenAsync(user.Id, cancellationToken, persist: false);

        stored.RevokedAt = DateTimeOffset.UtcNow;
        stored.ReplacedByTokenHash = Hash(newRefresh);

        _db.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = stored.ReplacedByTokenHash,
            ExpiresAt = DateTimeOffset.UtcNow.AddDays(_options.RefreshDays),
        });

        await _db.SaveChangesAsync(cancellationToken);

        return (new TokenPair(accessToken, newRefresh, expiresAt), user.Id, email, role);
    }

    public async Task RevokeAsync(string refreshToken, CancellationToken cancellationToken = default)
    {
        var hash = Hash(refreshToken);
        var stored = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.TokenHash == hash, cancellationToken);

        if (stored is not null && stored.RevokedAt is null)
        {
            stored.RevokedAt = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
        }
    }

    private (string Token, DateTimeOffset ExpiresAt) CreateAccessToken(Guid userId, string email, string role,
        Guid? customerId)
    {
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(_options.AccessMinutes);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Role, role),
            new("role", role),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        if (customerId.HasValue)
        {
            claims.Add(new Claim(Application.Common.AppClaimTypes.CustomerId, customerId.Value.ToString()));
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Key));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: expiresAt.UtcDateTime,
            signingCredentials: credentials);

        var encoded = new JwtSecurityTokenHandler().WriteToken(token);
        return (encoded, expiresAt);
    }

    private async Task<string> CreateRefreshTokenAsync(Guid userId, CancellationToken cancellationToken,
        bool persist = true)
    {
        var token = GenerateOpaqueToken();

        if (persist)
        {
            _db.RefreshTokens.Add(new RefreshToken
            {
                UserId = userId,
                TokenHash = Hash(token),
                ExpiresAt = DateTimeOffset.UtcNow.AddDays(_options.RefreshDays),
            });
            await _db.SaveChangesAsync(cancellationToken);
        }

        return token;
    }

    private static string GenerateOpaqueToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
    }

    private static string Hash(string value)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return Convert.ToBase64String(bytes);
    }
}
