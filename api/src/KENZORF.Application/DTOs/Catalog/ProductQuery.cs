using KENZORF.Application.DTOs.Common;
using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Catalog;

/// <summary>Filtres de recherche du catalogue public.</summary>
public sealed record ProductQuery
{
    public string? CategorySlug { get; init; }
    public Gender? Gender { get; init; }
    public string? Search { get; init; }
    public decimal? MinPrice { get; init; }
    public decimal? MaxPrice { get; init; }

    /// <summary>Tri : "newest" (défaut), "price_asc", "price_desc".</summary>
    public string? Sort { get; init; }

    public PaginationQuery Pagination { get; init; } = new();
}
