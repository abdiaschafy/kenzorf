using KENZORF.Domain.Common;

namespace KENZORF.Infrastructure.Identity;

/// <summary>
/// Refresh token opaque, stocké <b>hashé</b> (SHA-256) en base. Rotation à chaque usage :
/// l'ancien est révoqué et remplacé. Jamais le secret en clair côté serveur.
/// </summary>
public sealed class RefreshToken : BaseEntity
{
    public Guid UserId { get; set; }

    /// <summary>Hash SHA-256 (Base64) du token opaque remis au client.</summary>
    public string TokenHash { get; set; } = string.Empty;

    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? RevokedAt { get; set; }

    /// <summary>Hash du token de remplacement émis lors de la rotation (traçabilité).</summary>
    public string? ReplacedByTokenHash { get; set; }

    public bool IsActive => RevokedAt is null && ExpiresAt > DateTimeOffset.UtcNow;
}
