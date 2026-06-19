import type {
  AdminProductDto,
  AdminProductRequest,
  VariantRequest,
  AdminProductImageRequest,
} from '@app/core/interfaces/admin-product.interfaces';
import type { Gender } from '@app/core/constants/catalog.constants';
import type {
  ProductFormModel,
  ProductImageForm,
  ProductVariantForm,
} from './product-form.model';

export function emptyVariant(): ProductVariantForm {
  return {
    sku: '',
    size: '',
    color: '',
    colorHex: '',
    price: null,
    stockQuantity: 0,
    isActive: true,
  };
}

export function emptyImage(order: number): ProductImageForm {
  return { url: '', altText: '', isPrimary: order === 0, displayOrder: order };
}

export function emptyProductForm(): ProductFormModel {
  return {
    name: '',
    slug: '',
    shortDescription: '',
    description: '',
    categoryId: '',
    gender: '',
    material: '',
    careInstructions: '',
    basePrice: null,
    compareAtPrice: null,
    isFeatured: false,
    isActive: true,
  };
}

export function dtoToForm(dto: AdminProductDto): {
  model: ProductFormModel;
  images: ProductImageForm[];
  variants: ProductVariantForm[];
} {
  return {
    model: {
      name: dto.name,
      slug: dto.slug,
      shortDescription: dto.shortDescription ?? '',
      description: dto.description,
      categoryId: dto.category.id,
      gender: dto.gender,
      material: dto.material ?? '',
      careInstructions: dto.careInstructions ?? '',
      basePrice: dto.basePrice,
      compareAtPrice: dto.compareAtPrice ?? null,
      isFeatured: dto.isFeatured,
      isActive: dto.isActive,
    },
    images: dto.images.map((img) => ({
      url: img.url,
      altText: img.altText ?? '',
      isPrimary: img.isPrimary,
      displayOrder: img.displayOrder,
    })),
    variants: dto.variants.map((v) => ({
      id: v.id,
      sku: v.sku,
      size: v.size,
      color: v.color,
      colorHex: v.colorHex ?? '',
      price: v.price ?? null,
      stockQuantity: v.stockQuantity,
      isActive: v.isActive,
    })),
  };
}

function trimOrUndefined(value: string): string | undefined {
  const t = value.trim();
  return t === '' ? undefined : t;
}

export function formToRequest(
  model: ProductFormModel,
  images: readonly ProductImageForm[],
  variants: readonly ProductVariantForm[],
): AdminProductRequest {
  const mappedImages: AdminProductImageRequest[] = images.map((img, index) => ({
    url: img.url.trim(),
    altText: trimOrUndefined(img.altText),
    isPrimary: img.isPrimary,
    displayOrder: img.displayOrder ?? index,
  }));

  const mappedVariants: VariantRequest[] = variants.map((v) => ({
    id: v.id,
    sku: v.sku.trim(),
    size: v.size.trim(),
    color: v.color.trim(),
    colorHex: trimOrUndefined(v.colorHex),
    price: v.price ?? undefined,
    stockQuantity: v.stockQuantity ?? 0,
    isActive: v.isActive,
  }));

  return {
    name: model.name.trim(),
    slug: trimOrUndefined(model.slug),
    description: model.description.trim(),
    shortDescription: trimOrUndefined(model.shortDescription),
    categoryId: model.categoryId,
    basePrice: model.basePrice ?? 0,
    compareAtPrice: model.compareAtPrice ?? undefined,
    gender: model.gender as Gender,
    material: trimOrUndefined(model.material),
    careInstructions: trimOrUndefined(model.careInstructions),
    isFeatured: model.isFeatured,
    isActive: model.isActive,
    images: mappedImages,
    variants: mappedVariants,
  };
}
