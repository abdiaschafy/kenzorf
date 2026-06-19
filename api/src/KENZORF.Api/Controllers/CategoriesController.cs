using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Catalog;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers;

/// <summary>Catalogue public : catégories.</summary>
[ApiController]
[Route("api/categories")]
[AllowAnonymous]
public sealed class CategoriesController : ControllerBase
{
    private readonly ICatalogService _catalog;

    public CategoriesController(ICatalogService catalog)
    {
        _catalog = catalog;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<CategoryDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> GetAll(CancellationToken cancellationToken)
        => Ok(await _catalog.GetCategoriesAsync(cancellationToken));
}
