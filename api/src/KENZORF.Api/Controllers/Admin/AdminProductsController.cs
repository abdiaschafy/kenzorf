using KENZORF.Api.Models;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers.Admin;

/// <summary>Back-office : CRUD produits, variantes et images.</summary>
[ApiController]
[Route("api/admin/products")]
[Authorize(Roles = AppRoles.Admin)]
public sealed class AdminProductsController : ControllerBase
{
    private readonly IAdminProductService _products;
    private readonly IImageUploadService _uploads;

    public AdminProductsController(IAdminProductService products, IImageUploadService uploads)
    {
        _products = products;
        _uploads = uploads;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<AdminProductSummaryDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<AdminProductSummaryDto>>> GetAll(
        [FromQuery] string? search = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
        => Ok(await _products.GetProductsAsync(new PaginationQuery { Page = page, PageSize = pageSize }, search,
            cancellationToken));

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(AdminProductDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminProductDto>> Get(Guid id, CancellationToken cancellationToken)
        => Ok(await _products.GetProductAsync(id, cancellationToken));

    [HttpPost]
    [ProducesResponseType(typeof(AdminProductDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<AdminProductDto>> Create([FromBody] AdminProductRequest request,
        CancellationToken cancellationToken)
    {
        var created = await _products.CreateProductAsync(request, cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(AdminProductDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminProductDto>> Update(Guid id, [FromBody] AdminProductRequest request,
        CancellationToken cancellationToken)
        => Ok(await _products.UpdateProductAsync(id, request, cancellationToken));

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await _products.DeleteProductAsync(id, cancellationToken);
        return NoContent();
    }

    [HttpPost("{id:guid}/variants")]
    [ProducesResponseType(typeof(AdminProductDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminProductDto>> AddVariant(Guid id, [FromBody] VariantRequest request,
        CancellationToken cancellationToken)
        => Ok(await _products.AddVariantAsync(id, request, cancellationToken));

    [HttpPut("{id:guid}/variants/{variantId:guid}")]
    [ProducesResponseType(typeof(AdminProductDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminProductDto>> UpdateVariant(Guid id, Guid variantId,
        [FromBody] VariantRequest request, CancellationToken cancellationToken)
        => Ok(await _products.UpdateVariantAsync(id, variantId, request, cancellationToken));

    [HttpDelete("{id:guid}/variants/{variantId:guid}")]
    [ProducesResponseType(typeof(AdminProductDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<AdminProductDto>> DeleteVariant(Guid id, Guid variantId,
        CancellationToken cancellationToken)
        => Ok(await _products.DeleteVariantAsync(id, variantId, cancellationToken));

    [HttpPost("{id:guid}/images")]
    [ProducesResponseType(typeof(UploadResultDto), StatusCodes.Status200OK)]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<ActionResult<UploadResultDto>> AddImage(Guid id, [FromForm] AdminImageUploadForm form,
        CancellationToken cancellationToken)
    {
        // Deux modes : fichier multipart (upload local) ou URL distante.
        if (form.File is not null)
        {
            await using var stream = form.File.OpenReadStream();
            var uploaded = await _uploads.UploadAsync(stream, form.File.FileName, form.File.ContentType,
                cancellationToken);
            var result = await _products.AddImageAsync(id, uploaded.Url, form.AltText, form.IsPrimary,
                cancellationToken);
            return Ok(result);
        }

        return Ok(await _products.AddImageAsync(id, form.Url ?? string.Empty, form.AltText, form.IsPrimary,
            cancellationToken));
    }
}
