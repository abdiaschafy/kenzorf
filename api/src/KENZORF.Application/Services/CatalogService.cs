using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Catalog;
using KENZORF.Application.DTOs.Common;
using KENZORF.Application.Mapping;
using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Lecture du catalogue public (catégories, recherche produits, mise en avant, fiche).</summary>
public sealed class CatalogService : ICatalogService
{
    private const int FeaturedLimit = 12;

    private readonly IAppDbContext _db;

    public CatalogService(IAppDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<CategoryDto>> GetCategoriesAsync(CancellationToken cancellationToken = default)
    {
        var categories = await _db.Categories
            .AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.Name)
            .Select(c => new
            {
                Category = c,
                ProductCount = c.Products.Count(p => p.IsActive),
            })
            .ToListAsync(cancellationToken);

        return categories
            .Select(x => CatalogMapper.ToDto(x.Category, x.ProductCount))
            .ToList();
    }

    public async Task<PagedResult<ProductListItemDto>> GetProductsAsync(ProductQuery query,
        CancellationToken cancellationToken = default)
    {
        var products = _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive);

        if (!string.IsNullOrWhiteSpace(query.CategorySlug))
        {
            var slug = query.CategorySlug.Trim().ToLowerInvariant();
            products = products.Where(p => p.Category.Slug == slug);
        }

        if (query.Gender.HasValue)
        {
            products = products.Where(p => p.Gender == query.Gender.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim().ToLower();
            products = products.Where(p =>
                p.Name.ToLower().Contains(term) ||
                p.Description.ToLower().Contains(term));
        }

        if (query.MinPrice.HasValue)
        {
            products = products.Where(p => p.BasePrice >= query.MinPrice.Value);
        }

        if (query.MaxPrice.HasValue)
        {
            products = products.Where(p => p.BasePrice <= query.MaxPrice.Value);
        }

        products = query.Sort switch
        {
            "price_asc" => products.OrderBy(p => p.BasePrice).ThenByDescending(p => p.CreatedAt),
            "price_desc" => products.OrderByDescending(p => p.BasePrice).ThenByDescending(p => p.CreatedAt),
            _ => products.OrderByDescending(p => p.CreatedAt),
        };

        var total = await products.CountAsync(cancellationToken);

        var page = await products
            .Include(p => p.Images)
            .Include(p => p.Variants)
            .Skip(query.Pagination.Skip)
            .Take(query.Pagination.PageSize)
            .ToListAsync(cancellationToken);

        var items = page.Select(CatalogMapper.ToListItem).ToList();
        return PagedResult<ProductListItemDto>.Create(items, query.Pagination.Page, query.Pagination.PageSize, total);
    }

    public async Task<IReadOnlyList<ProductListItemDto>> GetFeaturedProductsAsync(
        CancellationToken cancellationToken = default)
    {
        var products = await _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.IsFeatured)
            .Include(p => p.Images)
            .Include(p => p.Variants)
            .OrderByDescending(p => p.CreatedAt)
            .Take(FeaturedLimit)
            .ToListAsync(cancellationToken);

        return products.Select(CatalogMapper.ToListItem).ToList();
    }

    public async Task<ProductDetailDto> GetProductBySlugAsync(string slug, CancellationToken cancellationToken = default)
    {
        var normalized = (slug ?? string.Empty).Trim().ToLowerInvariant();

        var product = await _db.Products
            .AsNoTracking()
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Variants)
            .FirstOrDefaultAsync(p => p.IsActive && p.Slug == normalized, cancellationToken);

        if (product is null)
        {
            throw new NotFoundException(ErrorCodes.ProductNotFound);
        }

        return CatalogMapper.ToDetail(product);
    }
}
