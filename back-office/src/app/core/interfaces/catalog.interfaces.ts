import type { Gender } from '@app/core/constants/catalog.constants';

/** Catégorie (spec : CategoryDto). */
export interface CategoryDto {
  readonly id: string;
  readonly name: string;
  readonly slug: string;
  readonly description?: string;
  readonly imageUrl?: string;
  readonly productCount: number;
}

/** Catégorie côté back-office (API : CategoryAdminDto, GET /api/admin/categories). */
export interface CategoryAdminDto {
  readonly id: string;
  readonly name: string;
  readonly slug: string;
  readonly description?: string;
  readonly imageUrl?: string;
  readonly displayOrder: number;
  readonly isActive: boolean;
  readonly productCount: number;
}

/** Référence légère de catégorie (spec : CategoryRefDto). */
export interface CategoryRefDto {
  readonly id: string;
  readonly name: string;
  readonly slug: string;
}

/** Item de liste produit (spec : ProductListItemDto). */
export interface ProductListItemDto {
  readonly id: string;
  readonly name: string;
  readonly slug: string;
  readonly basePrice: number;
  readonly compareAtPrice?: number;
  readonly currency: string;
  readonly primaryImageUrl?: string;
  readonly gender: Gender;
  readonly inStock: boolean;
  readonly isFeatured: boolean;
}

/** Image produit (spec : ImageDto). */
export interface ImageDto {
  readonly id: string;
  readonly url: string;
  readonly altText?: string;
  readonly isPrimary: boolean;
  readonly displayOrder: number;
}

/** Variante produit (spec : VariantDto). */
export interface VariantDto {
  readonly id: string;
  readonly sku: string;
  readonly size: string;
  readonly color: string;
  readonly colorHex?: string;
  readonly price: number;
  readonly stockQuantity: number;
  readonly inStock: boolean;
}

/** Détail produit public (spec : ProductDetailDto). */
export interface ProductDetailDto {
  readonly id: string;
  readonly name: string;
  readonly slug: string;
  readonly description: string;
  readonly shortDescription?: string;
  readonly basePrice: number;
  readonly compareAtPrice?: number;
  readonly currency: string;
  readonly gender: Gender;
  readonly material?: string;
  readonly careInstructions?: string;
  readonly category: CategoryRefDto;
  readonly images: ImageDto[];
  readonly variants: VariantDto[];
}
