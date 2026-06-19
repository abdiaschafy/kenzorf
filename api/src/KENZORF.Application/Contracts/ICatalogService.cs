using KENZORF.Application.DTOs.Catalog;
using KENZORF.Application.DTOs.Common;

namespace KENZORF.Application.Contracts;

/// <summary>Lecture du catalogue public : catégories et produits.</summary>
public interface ICatalogService
{
    Task<IReadOnlyList<CategoryDto>> GetCategoriesAsync(CancellationToken cancellationToken = default);

    Task<PagedResult<ProductListItemDto>> GetProductsAsync(ProductQuery query,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ProductListItemDto>> GetFeaturedProductsAsync(CancellationToken cancellationToken = default);

    Task<ProductDetailDto> GetProductBySlugAsync(string slug, CancellationToken cancellationToken = default);
}
