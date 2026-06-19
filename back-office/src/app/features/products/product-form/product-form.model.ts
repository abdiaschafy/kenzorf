import type { Gender } from '@app/core/constants/catalog.constants';

/**
 * Modèle local du formulaire produit (édition).
 * Ces types restent au plus près de la feature mais hors du composant
 * (règle « pas de déclaration inline dans le composant »).
 */
export interface ProductImageForm {
  url: string;
  altText: string;
  isPrimary: boolean;
  displayOrder: number;
}

export interface ProductVariantForm {
  id?: string;
  sku: string;
  size: string;
  color: string;
  colorHex: string;
  price: number | null;
  stockQuantity: number | null;
  isActive: boolean;
}

export interface ProductFormModel {
  name: string;
  slug: string;
  shortDescription: string;
  description: string;
  categoryId: string;
  gender: Gender | '';
  material: string;
  careInstructions: string;
  basePrice: number | null;
  compareAtPrice: number | null;
  isFeatured: boolean;
  isActive: boolean;
}
