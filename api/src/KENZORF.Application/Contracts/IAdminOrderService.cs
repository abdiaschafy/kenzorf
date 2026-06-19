using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Common;

namespace KENZORF.Application.Contracts;

/// <summary>Gestion des commandes et des clients côté back-office.</summary>
public interface IAdminOrderService
{
    Task<PagedResult<AdminOrderSummaryDto>> GetOrdersAsync(AdminOrderQuery query,
        CancellationToken cancellationToken = default);

    Task<AdminOrderDto> GetOrderAsync(Guid id, CancellationToken cancellationToken = default);

    Task<AdminOrderDto> UpdateStatusAsync(Guid id, UpdateOrderStatusRequest request,
        CancellationToken cancellationToken = default);

    Task<PagedResult<CustomerDto>> GetCustomersAsync(PaginationQuery pagination,
        CancellationToken cancellationToken = default);
}
