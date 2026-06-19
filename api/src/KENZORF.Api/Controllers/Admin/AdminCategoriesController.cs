using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers.Admin;

/// <summary>Back-office : CRUD catégories.</summary>
[ApiController]
[Route("api/admin/categories")]
[Authorize(Roles = AppRoles.Admin)]
public sealed class AdminCategoriesController : ControllerBase
{
    private readonly IAdminProductService _products;

    public AdminCategoriesController(IAdminProductService products)
    {
        _products = products;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<CategoryAdminDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<CategoryAdminDto>>> GetAll(CancellationToken cancellationToken)
        => Ok(await _products.GetCategoriesAsync(cancellationToken));

    [HttpPost]
    [ProducesResponseType(typeof(CategoryAdminDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<CategoryAdminDto>> Create([FromBody] CategoryRequest request,
        CancellationToken cancellationToken)
    {
        var created = await _products.CreateCategoryAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetAll), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(CategoryAdminDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<CategoryAdminDto>> Update(Guid id, [FromBody] CategoryRequest request,
        CancellationToken cancellationToken)
        => Ok(await _products.UpdateCategoryAsync(id, request, cancellationToken));

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _products.DeleteCategoryAsync(id, cancellationToken);
        return NoContent();
    }
}
