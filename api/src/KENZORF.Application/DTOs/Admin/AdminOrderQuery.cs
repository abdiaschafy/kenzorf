using KENZORF.Application.DTOs.Common;
using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Admin;

/// <summary>Filtres de la liste des commandes (back-office).</summary>
public sealed record AdminOrderQuery
{
    public OrderStatus? Status { get; init; }
    public string? Search { get; init; }
    public PaginationQuery Pagination { get; init; } = new();
}
