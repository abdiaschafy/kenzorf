using FluentValidation;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Common;
using KENZORF.Application.Mapping;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Gestion des commandes et des clients pour le back-office.</summary>
public sealed class AdminOrderService : IAdminOrderService
{
    private static readonly OrderStatus[] SpendStatuses =
    {
        OrderStatus.Paid, OrderStatus.Processing, OrderStatus.Shipped, OrderStatus.Delivered,
    };

    private readonly IAppDbContext _db;
    private readonly IValidator<UpdateOrderStatusRequest> _statusValidator;

    public AdminOrderService(IAppDbContext db, IValidator<UpdateOrderStatusRequest> statusValidator)
    {
        _db = db;
        _statusValidator = statusValidator;
    }

    public async Task<PagedResult<AdminOrderSummaryDto>> GetOrdersAsync(AdminOrderQuery query,
        CancellationToken cancellationToken = default)
    {
        var orders = _db.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .Include(o => o.Customer)
            .AsQueryable();

        if (query.Status.HasValue)
        {
            orders = orders.Where(o => o.Status == query.Status.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim().ToLower();
            orders = orders.Where(o =>
                o.OrderNumber.ToLower().Contains(term) ||
                (o.Customer != null && o.Customer.Email.ToLower().Contains(term)) ||
                o.ShippingFullName.ToLower().Contains(term));
        }

        orders = orders.OrderByDescending(o => o.CreatedAt);

        var total = await orders.CountAsync(cancellationToken);
        var page = await orders
            .Skip(query.Pagination.Skip)
            .Take(query.Pagination.PageSize)
            .ToListAsync(cancellationToken);

        var items = page.Select(AdminMapper.ToSummary).ToList();
        return PagedResult<AdminOrderSummaryDto>.Create(items, query.Pagination.Page, query.Pagination.PageSize, total);
    }

    public async Task<AdminOrderDto> GetOrderAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var order = await LoadOrderAsync(id, cancellationToken);
        return AdminMapper.ToDto(order);
    }

    public async Task<AdminOrderDto> UpdateStatusAsync(Guid id, UpdateOrderStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_statusValidator, request, cancellationToken);

        var order = await LoadOrderAsync(id, cancellationToken);

        if (!OrderStatusTransitions.CanTransition(order.Status, request.Status))
        {
            throw new ConflictException(ErrorCodes.OrderInvalidStatusTransition,
                new Dictionary<string, object?>
                {
                    ["from"] = order.Status.ToString(),
                    ["to"] = request.Status.ToString(),
                });
        }

        ApplyStatus(order, request.Status);
        order.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var reloaded = await LoadOrderAsync(id, cancellationToken);
        return AdminMapper.ToDto(reloaded);
    }

    public async Task<PagedResult<CustomerDto>> GetCustomersAsync(PaginationQuery pagination,
        CancellationToken cancellationToken = default)
    {
        var customers = _db.Customers
            .AsNoTracking()
            .OrderByDescending(c => c.CreatedAt);

        var total = await customers.CountAsync(cancellationToken);

        var page = await customers
            .Skip(pagination.Skip)
            .Take(pagination.PageSize)
            .Select(c => new
            {
                Customer = c,
                OrderCount = c.Orders.Count,
                TotalSpent = c.Orders
                    .Where(o => SpendStatuses.Contains(o.Status))
                    .Sum(o => (decimal?)o.Total) ?? 0m,
            })
            .ToListAsync(cancellationToken);

        var items = page
            .Select(x => AdminMapper.ToDto(x.Customer, x.OrderCount, x.TotalSpent, Currency.Xof))
            .ToList();

        return PagedResult<CustomerDto>.Create(items, pagination.Page, pagination.PageSize, total);
    }

    private static void ApplyStatus(Order order, OrderStatus status)
    {
        var now = DateTimeOffset.UtcNow;
        order.Status = status;
        switch (status)
        {
            case OrderStatus.Paid:
                order.PaidAt ??= now;
                break;
            case OrderStatus.Shipped:
                order.ShippedAt ??= now;
                break;
            case OrderStatus.Delivered:
                order.DeliveredAt ??= now;
                break;
            case OrderStatus.Cancelled:
                order.CancelledAt ??= now;
                break;
        }
    }

    private async Task<Order> LoadOrderAsync(Guid id, CancellationToken cancellationToken)
    {
        var order = await _db.Orders
            .Include(o => o.Items)
            .Include(o => o.Payments)
            .Include(o => o.Customer)
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

        if (order is null)
        {
            throw new NotFoundException(ErrorCodes.OrderNotFound);
        }

        return order;
    }
}
