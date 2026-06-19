using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Common;
using KENZORF.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers.Admin;

/// <summary>Back-office : liste / détail des commandes et changement de statut.</summary>
[ApiController]
[Route("api/admin/orders")]
[Authorize(Roles = AppRoles.Admin)]
public sealed class AdminOrdersController : ControllerBase
{
    private readonly IAdminOrderService _orders;

    public AdminOrdersController(IAdminOrderService orders)
    {
        _orders = orders;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<AdminOrderSummaryDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<AdminOrderSummaryDto>>> GetAll(
        [FromQuery] OrderStatus? status,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var query = new AdminOrderQuery
        {
            Status = status,
            Search = search,
            Pagination = new PaginationQuery { Page = page, PageSize = pageSize },
        };
        return Ok(await _orders.GetOrdersAsync(query, cancellationToken));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(AdminOrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminOrderDto>> Get(Guid id, CancellationToken cancellationToken)
        => Ok(await _orders.GetOrderAsync(id, cancellationToken));

    [HttpPut("{id:guid}/status")]
    [ProducesResponseType(typeof(AdminOrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminOrderDto>> UpdateStatus(Guid id,
        [FromBody] UpdateOrderStatusRequest request, CancellationToken cancellationToken)
        => Ok(await _orders.UpdateStatusAsync(id, request, cancellationToken));
}
