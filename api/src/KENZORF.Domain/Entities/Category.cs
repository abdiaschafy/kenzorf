using KENZORF.Domain.Common;

namespace KENZORF.Domain.Entities;

/// <summary>Catégorie du catalogue (ex. T-shirts, Vestes, Accessoires).</summary>
public class Category : AuditableEntity
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }

    public Guid? ParentId { get; set; }
    public Category? Parent { get; set; }

    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<Category> Children { get; set; } = new List<Category>();
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
