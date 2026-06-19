using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers.Admin;

/// <summary>Back-office : tableau de bord (CA, commandes, stock bas).</summary>
[ApiController]
[Route("api/admin/dashboard")]
[Authorize(Roles = AppRoles.Admin)]
public sealed class AdminDashboardController : ControllerBase
{
    private readonly IDashboardService _dashboard;

    public AdminDashboardController(IDashboardService dashboard)
    {
        _dashboard = dashboard;
    }

    [HttpGet]
    [ProducesResponseType(typeof(DashboardDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DashboardDto>> Get(CancellationToken cancellationToken)
        => Ok(await _dashboard.GetDashboardAsync(cancellationToken));
}
