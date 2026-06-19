namespace KENZORF.Application.DTOs.Admin;

/// <summary>Indicateurs du back-office : CA, répartition des commandes, dernières commandes, stock bas.</summary>
public sealed record DashboardDto(
    decimal RevenueTotal,
    decimal RevenueThisMonth,
    string Currency,
    IReadOnlyDictionary<string, int> OrdersByStatus,
    IReadOnlyList<AdminOrderSummaryDto> RecentOrders,
    IReadOnlyList<LowStockVariantDto> LowStockVariants);
