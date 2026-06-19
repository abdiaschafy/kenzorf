using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Orders;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers;

/// <summary>Commandes du client connecté (création + paiement, consultation, annulation).</summary>
[ApiController]
[Route("api/orders")]
[Authorize(Roles = AppRoles.Customer)]
public sealed class OrdersController : ControllerBase
{
    private readonly IOrderService _orders;

    public OrdersController(IOrderService orders)
    {
        _orders = orders;
    }

    [HttpPost]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<OrderDto>> Create([FromBody] CreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        var order = await _orders.CreateOrderAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = order.Id }, order);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<OrderSummaryDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<OrderSummaryDto>>> GetMine(CancellationToken cancellationToken)
        => Ok(await _orders.GetMyOrdersAsync(cancellationToken));

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<OrderDto>> GetById(Guid id, CancellationToken cancellationToken)
        => Ok(await _orders.GetMyOrderAsync(id, cancellationToken));

    [HttpPost("{id:guid}/cancel")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<OrderDto>> Cancel(Guid id, CancellationToken cancellationToken)
        => Ok(await _orders.CancelMyOrderAsync(id, cancellationToken));
}
