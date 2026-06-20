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
    private readonly IIdentityService _identity;
    private readonly JwtOptions _options;

    public TokenService(AppDbContext db, IIdentityService identity, IOptions<JwtOptions> options)
    {
        _db = db;
        _identity = identity;
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
        // Nettoyage opportuniste des jetons expirés (best-effort, ne bloque pas la rotation).
        await PurgeExpiredAsync(cancellationToken);

        var hash = Hash(refreshToken);

        var stored = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.TokenHash == hash, cancellationToken);

        if (stored is null)
        {
            // Jeton inconnu (jamais émis ou déjà purgé) : refus simple.
            return null;
        }

        // Détection de réutilisation : un jeton présenté alors qu'il est DÉJÀ révoqué signale un vol/replay
        // (le client légitime n'a en main que le dernier jeton émis). On invalide toute la famille issue de
        // ce jeton puis tous les jetons actifs restants du compte, et on refuse la rotation (fail-closed).
        if (stored.RevokedAt is not null)
        {
            await RevokeTokenFamilyAsync(stored, cancellationToken);
            await RevokeAllActiveForUserAsync(stored.UserId, cancellationToken);
            await _db.SaveChangesAsync(cancellationToken);
            return null;
        }

        // Jeton trouvé mais expiré : refus (il sera purgé au prochain passage).
        if (!stored.IsActive)
        {
            return null;
        }

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == stored.UserId, cancellationToken);
        if (user is null)
        {
            return null;
        }

        // Résolution du rôle déléguée à Identity (UserManager.GetRolesAsync), source unique de vérité.
        var role = await _identity.GetRoleAsync(user.Id, cancellationToken)
            ?? Application.Common.AppRoles.Customer;

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

    /// <summary>Révoque la chaîne de jetons issue de <paramref name="compromised"/> (suivi de ReplacedByTokenHash).</summary>
    private async Task RevokeTokenFamilyAsync(RefreshToken compromised, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var current = compromised;
        var guard = 0;

        while (current is not null && guard++ < 256)
        {
            if (current.RevokedAt is null)
            {
                current.RevokedAt = now;
            }

            var nextHash = current.ReplacedByTokenHash;
            if (string.IsNullOrEmpty(nextHash))
            {
                break;
            }

            current = await _db.RefreshTokens
                .FirstOrDefaultAsync(t => t.TokenHash == nextHash, cancellationToken);
        }
    }

    /// <summary>Révoque tous les jetons encore actifs du compte (confinement après détection de vol).</summary>
    private async Task RevokeAllActiveForUserAsync(Guid userId, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var active = await _db.RefreshTokens
            .Where(t => t.UserId == userId && t.RevokedAt == null)
            .ToListAsync(cancellationToken);

        foreach (var token in active)
        {
            token.RevokedAt = now;
        }
    }

    /// <summary>Supprime les jetons expirés (révoqués ou non) pour borner la table.</summary>
    private async Task PurgeExpiredAsync(CancellationToken cancellationToken)
    {
        var threshold = DateTimeOffset.UtcNow;
        var expired = await _db.RefreshTokens
            .Where(t => t.ExpiresAt <= threshold)
            .ToListAsync(cancellationToken);

        if (expired.Count > 0)
        {
            _db.RefreshTokens.RemoveRange(expired);
            await _db.SaveChangesAsync(cancellationToken);
        }
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
