using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Common;

namespace KENZORF.Application.Contracts;

/// <summary>Gestion des produits, variantes, images et catégories côté back-office.</summary>
public interface IAdminProductService
{
    Task<PagedResult<AdminProductSummaryDto>> GetProductsAsync(PaginationQuery pagination,
        CancellationToken cancellationToken = default);

    Task<AdminProductDto> GetProductAsync(Guid id, CancellationToken cancellationToken = default);

    Task<AdminProductDto> CreateProductAsync(AdminProductRequest request, CancellationToken cancellationToken = default);

    Task<AdminProductDto> UpdateProductAsync(Guid id, AdminProductRequest request,
        CancellationToken cancellationToken = default);

    Task DeleteProductAsync(Guid id, CancellationToken cancellationToken = default);

    Task<AdminProductDto> AddVariantAsync(Guid productId, VariantRequest request,
        CancellationToken cancellationToken = default);

    Task<AdminProductDto> UpdateVariantAsync(Guid productId, Guid variantId, VariantRequest request,
        CancellationToken cancellationToken = default);

    Task<AdminProductDto> DeleteVariantAsync(Guid productId, Guid variantId,
        CancellationToken cancellationToken = default);

    Task<UploadResultDto> AddImageAsync(Guid productId, string url, string? altText, bool isPrimary,
        CancellationToken cancellationToken = default);

    // Catégories (back-office)
    Task<IReadOnlyList<CategoryAdminDto>> GetCategoriesAsync(CancellationToken cancellationToken = default);

    Task<CategoryAdminDto> CreateCategoryAsync(CategoryRequest request, CancellationToken cancellationToken = default);

    Task<CategoryAdminDto> UpdateCategoryAsync(Guid id, CategoryRequest request,
        CancellationToken cancellationToken = default);

    Task DeleteCategoryAsync(Guid id, CancellationToken cancellationToken = default);
}
