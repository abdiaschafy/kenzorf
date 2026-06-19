using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers.Admin;

/// <summary>Back-office : liste des clients.</summary>
[ApiController]
[Route("api/admin/customers")]
[Authorize(Roles = AppRoles.Admin)]
public sealed class AdminCustomersController : ControllerBase
{
    private readonly IAdminOrderService _orders;

    public AdminCustomersController(IAdminOrderService orders)
    {
        _orders = orders;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<CustomerDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<CustomerDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
        => Ok(await _orders.GetCustomersAsync(new PaginationQuery { Page = page, PageSize = pageSize },
            cancellationToken));
}
