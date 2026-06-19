import type { Gender } from '@app/core/constants/catalog.constants';
import type { CategoryRefDto, ImageDto } from './catalog.interfaces';

/** Image en entrée d'un produit admin (spec : AdminProductRequest.images[]). */
export interface AdminProductImageRequest {
  url: string;
  altText?: string;
  isPrimary: boolean;
  displayOrder: number;
}

/** Variante en entrée (spec : VariantRequest). */
export interface VariantRequest {
  id?: string;
  sku: string;
  size: string;
  color: string;
  colorHex?: string;
  price?: number;
  stockQuantity: number;
  isActive: boolean;
}

/** Création / mise à jour d'un produit (spec : AdminProductRequest). */
export interface AdminProductRequest {
  name: string;
  slug?: string;
  description: string;
  shortDescription?: string;
  categoryId: string;
  basePrice: number;
  compareAtPrice?: number;
  gender: Gender;
  material?: string;
  careInstructions?: string;
  isFeatured: boolean;
  isActive: boolean;
  images: AdminProductImageRequest[];
  variants: VariantRequest[];
}

/**
 * Item de liste produit côté back-office (API : AdminProductSummaryDto).
 * Forme renvoyée par `GET /api/admin/products` (paginée). À ne pas confondre
 * avec `AdminProductDto` (détail).
 */
export interface AdminProductSummaryDto {
  readonly id: string;
  readonly name: string;
  readonly slug: string;
  readonly categoryName: string;
  readonly basePrice: number;
  readonly currency: string;
  readonly gender: Gender;
  readonly totalStock: number;
  readonly variantCount: number;
  readonly isFeatured: boolean;
  readonly isActive: boolean;
  readonly primaryImageUrl?: string;
}

/** Variante côté admin (API : AdminVariantDto). */
export interface AdminVariantDto {
  readonly id: string;
  readonly sku: string;
  readonly size: string;
  readonly color: string;
  readonly colorHex?: string;
  readonly price?: number;
  readonly effectivePrice: number;
  readonly stockQuantity: number;
  readonly isActive: boolean;
}

/** Produit côté admin — détail (API : AdminProductDto). */
export interface AdminProductDto {
  readonly id: string;
  readonly name: string;
  readonly slug: string;
  readonly description: string;
  readonly shortDescription?: string;
  readonly category: CategoryRefDto;
  readonly basePrice: number;
  readonly compareAtPrice?: number;
  readonly currency: string;
  readonly gender: Gender;
  readonly material?: string;
  readonly careInstructions?: string;
  readonly isFeatured: boolean;
  readonly isActive: boolean;
  readonly totalStock: number;
  readonly images: ImageDto[];
  readonly variants: AdminVariantDto[];
  readonly createdAt: string;
  readonly updatedAt?: string;
}

/** Réponse d'upload d'image (spec : POST /products/{id}/images, /uploads → { url }). */
export interface UploadResultDto {
  readonly url: string;
}

/** Requête de catégorie (API : CategoryRequest). */
export interface CategoryRequest {
  name: string;
  slug?: string;
  description?: string;
  imageUrl?: string;
  displayOrder: number;
  isActive: boolean;
}
