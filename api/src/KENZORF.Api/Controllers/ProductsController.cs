using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Catalog;
using KENZORF.Application.DTOs.Common;
using KENZORF.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers;

/// <summary>Catalogue public : recherche, mise en avant et fiche produit.</summary>
[ApiController]
[Route("api/products")]
[AllowAnonymous]
public sealed class ProductsController : ControllerBase
{
    private readonly ICatalogService _catalog;

    public ProductsController(ICatalogService catalog)
    {
        _catalog = catalog;
    }

    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<ProductListItemDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ProductListItemDto>>> Search(
        [FromQuery] string? categorySlug,
        [FromQuery] Gender? gender,
        [FromQuery] string? search,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] string? sort,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var query = new ProductQuery
        {
            CategorySlug = categorySlug,
            Gender = gender,
            Search = search,
            MinPrice = minPrice,
            MaxPrice = maxPrice,
            Sort = sort,
            Pagination = new PaginationQuery { Page = page, PageSize = pageSize },
        };

        return Ok(await _catalog.GetProductsAsync(query, cancellationToken));
    }

    [HttpGet("featured")]
    [ProducesResponseType(typeof(IReadOnlyList<ProductListItemDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ProductListItemDto>>> Featured(CancellationToken cancellationToken)
        => Ok(await _catalog.GetFeaturedProductsAsync(cancellationToken));

    [HttpGet("{slug}")]
    [ProducesResponseType(typeof(ProductDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductDetailDto>> GetBySlug(string slug, CancellationToken cancellationToken)
        => Ok(await _catalog.GetProductBySlugAsync(slug, cancellationToken));
}
