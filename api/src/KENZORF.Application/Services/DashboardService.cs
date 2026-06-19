using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.Mapping;
using KENZORF.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Calcule les indicateurs du back-office (CA, commandes par statut, récentes, stock bas).</summary>
public sealed class DashboardService : IDashboardService
{
    private const int LowStockThreshold = 5;
    private const int RecentOrdersLimit = 10;
    private const int LowStockLimit = 20;

    private static readonly OrderStatus[] RevenueStatuses =
    {
        OrderStatus.Paid, OrderStatus.Processing, OrderStatus.Shipped, OrderStatus.Delivered,
    };

    private readonly IAppDbContext _db;

    public DashboardService(IAppDbContext db)
    {
        _db = db;
    }

    public async Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;
        var startOfMonth = new DateTimeOffset(now.Year, now.Month, 1, 0, 0, 0, TimeSpan.Zero);

        var paidOrders = _db.Orders
            .AsNoTracking()
            .Where(o => RevenueStatuses.Contains(o.Status));

        var revenueTotal = await paidOrders.SumAsync(o => (decimal?)o.Total, cancellationToken) ?? 0m;
        var revenueThisMonth = await paidOrders
            .Where(o => o.PaidAt != null && o.PaidAt >= startOfMonth)
            .SumAsync(o => (decimal?)o.Total, cancellationToken) ?? 0m;

        var statusCounts = await _db.Orders
            .AsNoTracking()
            .GroupBy(o => o.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var ordersByStatus = statusCounts.ToDictionary(x => x.Status.ToString(), x => x.Count);

        var recentOrders = await _db.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .Include(o => o.Customer)
            .OrderByDescending(o => o.CreatedAt)
            .Take(RecentOrdersLimit)
            .ToListAsync(cancellationToken);

        var lowStock = await _db.ProductVariants
            .AsNoTracking()
            .Include(v => v.Product)
            .Where(v => v.IsActive && v.StockQuantity <= LowStockThreshold)
            .OrderBy(v => v.StockQuantity)
            .Take(LowStockLimit)
            .ToListAsync(cancellationToken);

        return new DashboardDto(
            revenueTotal,
            revenueThisMonth,
            Currency.Xof,
            ordersByStatus,
            recentOrders.Select(AdminMapper.ToSummary).ToList(),
            lowStock.Select(AdminMapper.ToLowStock).ToList());
    }
}
