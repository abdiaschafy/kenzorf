using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Addresses;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers;

/// <summary>Adresses de livraison du client connecté.</summary>
[ApiController]
[Route("api/addresses")]
[Authorize(Roles = AppRoles.Customer)]
public sealed class AddressesController : ControllerBase
{
    private readonly IAddressService _addresses;

    public AddressesController(IAddressService addresses)
    {
        _addresses = addresses;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<AddressDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<AddressDto>>> GetMine(CancellationToken cancellationToken)
        => Ok(await _addresses.GetMyAddressesAsync(cancellationToken));

    [HttpPost]
    [ProducesResponseType(typeof(AddressDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<AddressDto>> Create([FromBody] AddressRequest request,
        CancellationToken cancellationToken)
    {
        var created = await _addresses.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetMine), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(AddressDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AddressDto>> Update(Guid id, [FromBody] AddressRequest request,
        CancellationToken cancellationToken)
        => Ok(await _addresses.UpdateAsync(id, request, cancellationToken));

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _addresses.DeleteAsync(id, cancellationToken);
        return NoContent();
    }
}
