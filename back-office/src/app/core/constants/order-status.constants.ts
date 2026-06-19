/**
 * Statuts de commande — alignés sur l'enum .NET `OrderStatus` (string).
 * Le projet n'utilise pas `enum` TS : `const … as const` + union type.
 */
export const ORDER_STATUS = {
  Pending: 'Pending',
  Paid: 'Paid',
  Processing: 'Processing',
  Shipped: 'Shipped',
  Delivered: 'Delivered',
  Cancelled: 'Cancelled',
  Refunded: 'Refunded',
} as const;

export type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS];

export const ORDER_STATUS_VALUES: readonly OrderStatus[] = Object.values(ORDER_STATUS);

/** Clé i18n du libellé pour un statut donné. */
export const ORDER_STATUS_LABEL_KEY: Record<OrderStatus, string> = {
  Pending: 'orderStatus.pending',
  Paid: 'orderStatus.paid',
  Processing: 'orderStatus.processing',
  Shipped: 'orderStatus.shipped',
  Delivered: 'orderStatus.delivered',
  Cancelled: 'orderStatus.cancelled',
  Refunded: 'orderStatus.refunded',
};

/** Variante de badge (mappée sur le kit UI) par statut. */
export type StatusTone = 'neutral' | 'info' | 'warning' | 'success' | 'danger' | 'accent';

export const ORDER_STATUS_TONE: Record<OrderStatus, StatusTone> = {
  Pending: 'warning',
  Paid: 'info',
  Processing: 'accent',
  Shipped: 'info',
  Delivered: 'success',
  Cancelled: 'danger',
  Refunded: 'neutral',
};

/**
 * Transitions de statut autorisées côté UI (le back reste l'autorité).
 * Permet de ne proposer que des cibles cohérentes dans le sélecteur.
 */
export const ORDER_STATUS_TRANSITIONS: Record<OrderStatus, readonly OrderStatus[]> = {
  Pending: ['Paid', 'Cancelled'],
  Paid: ['Processing', 'Cancelled', 'Refunded'],
  Processing: ['Shipped', 'Cancelled'],
  Shipped: ['Delivered'],
  Delivered: ['Refunded'],
  Cancelled: [],
  Refunded: [],
};
