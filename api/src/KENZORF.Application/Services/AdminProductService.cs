using FluentValidation;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using KENZORF.Application.DTOs.Common;
using KENZORF.Application.Mapping;
using KENZORF.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Gestion produits / variantes / images / catégories pour le back-office.</summary>
public sealed class AdminProductService : IAdminProductService
{
    private readonly IAppDbContext _db;
    private readonly IValidator<AdminProductRequest> _productValidator;
    private readonly IValidator<VariantRequest> _variantValidator;
    private readonly IValidator<CategoryRequest> _categoryValidator;

    public AdminProductService(
        IAppDbContext db,
        IValidator<AdminProductRequest> productValidator,
        IValidator<VariantRequest> variantValidator,
        IValidator<CategoryRequest> categoryValidator)
    {
        _db = db;
        _productValidator = productValidator;
        _variantValidator = variantValidator;
        _categoryValidator = categoryValidator;
    }

    public async Task<PagedResult<AdminProductSummaryDto>> GetProductsAsync(PaginationQuery pagination,
        CancellationToken cancellationToken = default)
    {
        var query = _db.Products
            .AsNoTracking()
            .Include(p => p.Category)
            .Include(p => p.Variants)
            .Include(p => p.Images)
            .OrderByDescending(p => p.CreatedAt);

        var total = await query.CountAsync(cancellationToken);
        var page = await query
            .Skip(pagination.Skip)
            .Take(pagination.PageSize)
            .ToListAsync(cancellationToken);

        var items = page.Select(AdminMapper.ToSummary).ToList();
        return PagedResult<AdminProductSummaryDto>.Create(items, pagination.Page, pagination.PageSize, total);
    }

    public async Task<AdminProductDto> GetProductAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var product = await LoadProductAsync(id, cancellationToken);
        return AdminMapper.ToDto(product);
    }

    public async Task<AdminProductDto> CreateProductAsync(AdminProductRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_productValidator, request, cancellationToken);
        await EnsureCategoryExistsAsync(request.CategoryId, cancellationToken);

        var slug = await ResolveProductSlugAsync(request.Slug, request.Name, null, cancellationToken);
        await EnsureSkusAreUniqueAsync(request.Variants.Select(v => v.Sku), null, cancellationToken);

        var product = new Product
        {
            Name = request.Name.Trim(),
            Slug = slug,
            Description = request.Description.Trim(),
            ShortDescription = request.ShortDescription?.Trim(),
            CategoryId = request.CategoryId,
            BasePrice = request.BasePrice,
            CompareAtPrice = request.CompareAtPrice,
            Currency = Currency.Xof,
            Gender = request.Gender,
            Material = request.Material?.Trim(),
            CareInstructions = request.CareInstructions?.Trim(),
            IsFeatured = request.IsFeatured,
            IsActive = request.IsActive,
        };

        foreach (var image in NormalizeImages(request.Images))
        {
            product.Images.Add(image);
        }

        foreach (var variant in request.Variants)
        {
            product.Variants.Add(BuildVariant(variant));
        }

        _db.Products.Add(product);
        await _db.SaveChangesAsync(cancellationToken);

        var created = await LoadProductAsync(product.Id, cancellationToken);
        return AdminMapper.ToDto(created);
    }

    public async Task<AdminProductDto> UpdateProductAsync(Guid id, AdminProductRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_productValidator, request, cancellationToken);
        await EnsureCategoryExistsAsync(request.CategoryId, cancellationToken);

        var product = await LoadProductAsync(id, cancellationToken);

        product.Name = request.Name.Trim();
        product.Slug = await ResolveProductSlugAsync(request.Slug, request.Name, product.Id, cancellationToken);
        product.Description = request.Description.Trim();
        product.ShortDescription = request.ShortDescription?.Trim();
        product.CategoryId = request.CategoryId;
        product.BasePrice = request.BasePrice;
        product.CompareAtPrice = request.CompareAtPrice;
        product.Gender = request.Gender;
        product.Material = request.Material?.Trim();
        product.CareInstructions = request.CareInstructions?.Trim();
        product.IsFeatured = request.IsFeatured;
        product.IsActive = request.IsActive;
        product.UpdatedAt = DateTimeOffset.UtcNow;

        // Images : remplacement complet (le back-office envoie le jeu courant).
        _db.ProductImages.RemoveRange(product.Images);
        product.Images.Clear();
        foreach (var image in NormalizeImages(request.Images))
        {
            product.Images.Add(image);
        }

        await EnsureSkusAreUniqueAsync(request.Variants.Select(v => v.Sku), product.Id, cancellationToken);
        SyncVariants(product, request.Variants);

        await _db.SaveChangesAsync(cancellationToken);

        var updated = await LoadProductAsync(product.Id, cancellationToken);
        return AdminMapper.ToDto(updated);
    }

    public async Task DeleteProductAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var product = await LoadProductAsync(id, cancellationToken);
        _db.Products.Remove(product);
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<AdminProductDto> AddVariantAsync(Guid productId, VariantRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_variantValidator, request, cancellationToken);
        var product = await LoadProductAsync(productId, cancellationToken);

        await EnsureSkusAreUniqueAsync(new[] { request.Sku }, product.Id, cancellationToken);
        product.Variants.Add(BuildVariant(request));
        product.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
        var updated = await LoadProductAsync(productId, cancellationToken);
        return AdminMapper.ToDto(updated);
    }

    public async Task<AdminProductDto> UpdateVariantAsync(Guid productId, Guid variantId, VariantRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_variantValidator, request, cancellationToken);
        var product = await LoadProductAsync(productId, cancellationToken);

        var variant = product.Variants.FirstOrDefault(v => v.Id == variantId);
        if (variant is null)
        {
            throw new NotFoundException(ErrorCodes.ProductVariantNotFound);
        }

        await EnsureSkusAreUniqueAsync(new[] { request.Sku }, product.Id, cancellationToken, variantId);
        ApplyVariant(variant, request);
        product.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
        var updated = await LoadProductAsync(productId, cancellationToken);
        return AdminMapper.ToDto(updated);
    }

    public async Task<AdminProductDto> DeleteVariantAsync(Guid productId, Guid variantId,
        CancellationToken cancellationToken = default)
    {
        var product = await LoadProductAsync(productId, cancellationToken);
        var variant = product.Variants.FirstOrDefault(v => v.Id == variantId);
        if (variant is null)
        {
            throw new NotFoundException(ErrorCodes.ProductVariantNotFound);
        }

        _db.ProductVariants.Remove(variant);
        product.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
        var updated = await LoadProductAsync(productId, cancellationToken);
        return AdminMapper.ToDto(updated);
    }

    public async Task<UploadResultDto> AddImageAsync(Guid productId, string url, string? altText, bool isPrimary,
        CancellationToken cancellationToken = default)
    {
        var product = await LoadProductAsync(productId, cancellationToken);

        if (string.IsNullOrWhiteSpace(url))
        {
            throw new Common.ValidationException(ErrorCodes.UploadInvalidFile);
        }

        if (isPrimary)
        {
            foreach (var existing in product.Images)
            {
                existing.IsPrimary = false;
            }
        }

        var image = new ProductImage
        {
            ProductId = product.Id,
            Url = url.Trim(),
            AltText = altText?.Trim(),
            IsPrimary = isPrimary || product.Images.Count == 0,
            DisplayOrder = product.Images.Count,
        };
        product.Images.Add(image);
        product.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
        return new UploadResultDto(image.Url);
    }

    public async Task<IReadOnlyList<CategoryAdminDto>> GetCategoriesAsync(CancellationToken cancellationToken = default)
    {
        var categories = await _db.Categories
            .AsNoTracking()
            .OrderBy(c => c.DisplayOrder)
            .ThenBy(c => c.Name)
            .Select(c => new { Category = c, ProductCount = c.Products.Count })
            .ToListAsync(cancellationToken);

        return categories.Select(x => AdminMapper.ToAdminDto(x.Category, x.ProductCount)).ToList();
    }

    public async Task<CategoryAdminDto> CreateCategoryAsync(CategoryRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_categoryValidator, request, cancellationToken);

        var slug = await ResolveCategorySlugAsync(request.Slug, request.Name, null, cancellationToken);

        var category = new Category
        {
            Name = request.Name.Trim(),
            Slug = slug,
            Description = request.Description?.Trim(),
            ImageUrl = request.ImageUrl?.Trim(),
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive,
        };

        _db.Categories.Add(category);
        await _db.SaveChangesAsync(cancellationToken);

        return AdminMapper.ToAdminDto(category, 0);
    }

    public async Task<CategoryAdminDto> UpdateCategoryAsync(Guid id, CategoryRequest request,
        CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_categoryValidator, request, cancellationToken);

        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        if (category is null)
        {
            throw new NotFoundException(ErrorCodes.CategoryNotFound);
        }

        category.Name = request.Name.Trim();
        category.Slug = await ResolveCategorySlugAsync(request.Slug, request.Name, category.Id, cancellationToken);
        category.Description = request.Description?.Trim();
        category.ImageUrl = request.ImageUrl?.Trim();
        category.DisplayOrder = request.DisplayOrder;
        category.IsActive = request.IsActive;
        category.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var productCount = await _db.Products.CountAsync(p => p.CategoryId == category.Id, cancellationToken);
        return AdminMapper.ToAdminDto(category, productCount);
    }

    public async Task DeleteCategoryAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var category = await _db.Categories.FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        if (category is null)
        {
            throw new NotFoundException(ErrorCodes.CategoryNotFound);
        }

        var hasProducts = await _db.Products.AnyAsync(p => p.CategoryId == id, cancellationToken);
        if (hasProducts)
        {
            throw new ConflictException(ErrorCodes.CategoryHasProducts);
        }

        _db.Categories.Remove(category);
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<Product> LoadProductAsync(Guid id, CancellationToken cancellationToken)
    {
        var product = await _db.Products
            .Include(p => p.Category)
            .Include(p => p.Images)
            .Include(p => p.Variants)
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        if (product is null)
        {
            throw new NotFoundException(ErrorCodes.ProductNotFound);
        }

        return product;
    }

    private async Task EnsureCategoryExistsAsync(Guid categoryId, CancellationToken cancellationToken)
    {
        var exists = await _db.Categories.AnyAsync(c => c.Id == categoryId, cancellationToken);
        if (!exists)
        {
            throw new NotFoundException(ErrorCodes.CategoryNotFound);
        }
    }

    private void SyncVariants(Product product, IReadOnlyList<VariantRequest> requested)
    {
        var keptIds = requested.Where(v => v.Id.HasValue).Select(v => v.Id!.Value).ToHashSet();

        var toRemove = product.Variants.Where(v => !keptIds.Contains(v.Id)).ToList();
        if (toRemove.Count > 0)
        {
            _db.ProductVariants.RemoveRange(toRemove);
            foreach (var removed in toRemove)
            {
                product.Variants.Remove(removed);
            }
        }

        foreach (var req in requested)
        {
            if (req.Id.HasValue)
            {
                var variant = product.Variants.FirstOrDefault(v => v.Id == req.Id.Value);
                if (variant is not null)
                {
                    ApplyVariant(variant, req);
                    continue;
                }
            }

            product.Variants.Add(BuildVariant(req));
        }
    }

    private static ProductVariant BuildVariant(VariantRequest request)
    {
        var variant = new ProductVariant();
        ApplyVariant(variant, request);
        return variant;
    }

    private static void ApplyVariant(ProductVariant variant, VariantRequest request)
    {
        variant.Sku = request.Sku.Trim();
        variant.Size = request.Size?.Trim() ?? string.Empty;
        variant.Color = request.Color.Trim();
        variant.ColorHex = request.ColorHex?.Trim();
        variant.Price = request.Price;
        variant.StockQuantity = request.StockQuantity;
        variant.IsActive = request.IsActive;
        variant.UpdatedAt = DateTimeOffset.UtcNow;
    }

    private static IEnumerable<ProductImage> NormalizeImages(IReadOnlyList<ProductImageRequest> images)
    {
        var ordered = images
            .Where(i => !string.IsNullOrWhiteSpace(i.Url))
            .OrderBy(i => i.DisplayOrder)
            .ToList();

        var hasPrimary = ordered.Any(i => i.IsPrimary);
        for (var index = 0; index < ordered.Count; index++)
        {
            var image = ordered[index];
            yield return new ProductImage
            {
                Url = image.Url.Trim(),
                AltText = image.AltText?.Trim(),
                IsPrimary = image.IsPrimary || (!hasPrimary && index == 0),
                DisplayOrder = index,
            };
        }
    }

    private async Task EnsureSkusAreUniqueAsync(IEnumerable<string> skus, Guid? productId,
        CancellationToken cancellationToken, Guid? ignoreVariantId = null)
    {
        var normalized = skus
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Select(s => s.Trim())
            .ToList();

        if (normalized.Count == 0)
        {
            return;
        }

        // Doublons internes à la requête.
        var duplicateInRequest = normalized
            .GroupBy(s => s, StringComparer.OrdinalIgnoreCase)
            .Any(g => g.Count() > 1);
        if (duplicateInRequest)
        {
            throw new ConflictException(ErrorCodes.ProductVariantSkuTaken);
        }

        var query = _db.ProductVariants.AsNoTracking().Where(v => normalized.Contains(v.Sku));
        if (productId.HasValue)
        {
            query = query.Where(v => v.ProductId != productId.Value);
        }

        if (ignoreVariantId.HasValue)
        {
            query = query.Where(v => v.Id != ignoreVariantId.Value);
        }

        var clash = await query.AnyAsync(cancellationToken);
        if (clash)
        {
            throw new ConflictException(ErrorCodes.ProductVariantSkuTaken);
        }
    }

    private async Task<string> ResolveProductSlugAsync(string? requestedSlug, string name, Guid? currentId,
        CancellationToken cancellationToken)
    {
        var baseSlug = Slugifier.Slugify(string.IsNullOrWhiteSpace(requestedSlug) ? name : requestedSlug);
        if (string.IsNullOrWhiteSpace(baseSlug))
        {
            baseSlug = "produit";
        }

        var slug = baseSlug;
        var suffix = 2;
        while (await _db.Products.AnyAsync(p => p.Slug == slug && p.Id != currentId, cancellationToken))
        {
            slug = $"{baseSlug}-{suffix++}";
        }

        return slug;
    }

    private async Task<string> ResolveCategorySlugAsync(string? requestedSlug, string name, Guid? currentId,
        CancellationToken cancellationToken)
    {
        var baseSlug = Slugifier.Slugify(string.IsNullOrWhiteSpace(requestedSlug) ? name : requestedSlug);
        if (string.IsNullOrWhiteSpace(baseSlug))
        {
            baseSlug = "categorie";
        }

        var slug = baseSlug;
        var suffix = 2;
        while (await _db.Categories.AnyAsync(c => c.Slug == slug && c.Id != currentId, cancellationToken))
        {
            slug = $"{baseSlug}-{suffix++}";
        }

        return slug;
    }
}
