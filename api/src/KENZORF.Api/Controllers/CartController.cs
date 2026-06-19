using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Cart;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers;

/// <summary>Panier serveur du client connecté.</summary>
[ApiController]
[Route("api/cart")]
[Authorize(Roles = AppRoles.Customer)]
public sealed class CartController : ControllerBase
{
    private readonly ICartService _cart;

    public CartController(ICartService cart)
    {
        _cart = cart;
    }

    [HttpGet]
    [ProducesResponseType(typeof(CartDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<CartDto>> Get(CancellationToken cancellationToken)
        => Ok(await _cart.GetCartAsync(cancellationToken));

    [HttpPost("items")]
    [ProducesResponseType(typeof(CartDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<CartDto>> AddItem([FromBody] AddCartItemRequest request,
        CancellationToken cancellationToken)
        => Ok(await _cart.AddItemAsync(request, cancellationToken));

    [HttpPut("items/{itemId:guid}")]
    [ProducesResponseType(typeof(CartDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<CartDto>> UpdateItem(Guid itemId, [FromBody] UpdateCartItemRequest request,
        CancellationToken cancellationToken)
        => Ok(await _cart.UpdateItemAsync(itemId, request, cancellationToken));

    [HttpDelete("items/{itemId:guid}")]
    [ProducesResponseType(typeof(CartDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<CartDto>> RemoveItem(Guid itemId, CancellationToken cancellationToken)
        => Ok(await _cart.RemoveItemAsync(itemId, cancellationToken));

    [HttpDelete]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Clear(CancellationToken cancellationToken)
    {
        await _cart.ClearAsync(cancellationToken);
        return NoContent();
    }
}
