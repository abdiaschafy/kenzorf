namespace KENZORF.Domain.Common;

/// <summary>Base de toutes les entités persistées (identifiant GUID).</summary>
public abstract class BaseEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
}

/// <summary>Entité avec horodatage de création / mise à jour.</summary>
public abstract class AuditableEntity : BaseEntity
{
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
}
