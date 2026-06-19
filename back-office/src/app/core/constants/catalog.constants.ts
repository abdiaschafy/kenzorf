/** Genre / rayon — aligné sur l'enum .NET `Gender` (string). */
export const GENDER = {
  Men: 'Men',
  Women: 'Women',
  Unisex: 'Unisex',
  Kids: 'Kids',
} as const;

export type Gender = (typeof GENDER)[keyof typeof GENDER];

export const GENDER_VALUES: readonly Gender[] = Object.values(GENDER);

export const GENDER_LABEL_KEY: Record<Gender, string> = {
  Men: 'gender.men',
  Women: 'gender.women',
  Unisex: 'gender.unisex',
  Kids: 'gender.kids',
};

/** Options de tri du catalogue (query `sort`). */
export const PRODUCT_SORT = {
  Newest: 'newest',
  PriceAsc: 'price_asc',
  PriceDesc: 'price_desc',
} as const;

export type ProductSort = (typeof PRODUCT_SORT)[keyof typeof PRODUCT_SORT];

export const PRODUCT_SORT_LABEL_KEY: Record<ProductSort, string> = {
  newest: 'productSort.newest',
  price_asc: 'productSort.priceAsc',
  price_desc: 'productSort.priceDesc',
};

/** Devise par défaut de la boutique. */
export const DEFAULT_CURRENCY = 'XOF';
