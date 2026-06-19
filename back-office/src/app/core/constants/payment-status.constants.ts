import type { StatusTone } from './order-status.constants';

/** Statuts de paiement — alignés sur l'enum .NET `PaymentStatus` (string). */
export const PAYMENT_STATUS = {
  Pending: 'Pending',
  Initiated: 'Initiated',
  Succeeded: 'Succeeded',
  Failed: 'Failed',
  Cancelled: 'Cancelled',
  Refunded: 'Refunded',
} as const;

export type PaymentStatus = (typeof PAYMENT_STATUS)[keyof typeof PAYMENT_STATUS];

export const PAYMENT_STATUS_LABEL_KEY: Record<PaymentStatus, string> = {
  Pending: 'paymentStatus.pending',
  Initiated: 'paymentStatus.initiated',
  Succeeded: 'paymentStatus.succeeded',
  Failed: 'paymentStatus.failed',
  Cancelled: 'paymentStatus.cancelled',
  Refunded: 'paymentStatus.refunded',
};

export const PAYMENT_STATUS_TONE: Record<PaymentStatus, StatusTone> = {
  Pending: 'neutral',
  Initiated: 'warning',
  Succeeded: 'success',
  Failed: 'danger',
  Cancelled: 'neutral',
  Refunded: 'info',
};

/** Méthodes de paiement KPay (alignées `CreateOrderRequest.paymentMethod`). */
export const PAYMENT_METHOD = {
  OrangeMoney: 'orange_money',
  Mtn: 'mtn',
  Wave: 'wave',
  Moov: 'moov',
  Card: 'card',
} as const;

export type PaymentMethod = (typeof PAYMENT_METHOD)[keyof typeof PAYMENT_METHOD];

export const PAYMENT_METHOD_LABEL_KEY: Record<PaymentMethod, string> = {
  orange_money: 'paymentMethod.orangeMoney',
  mtn: 'paymentMethod.mtn',
  wave: 'paymentMethod.wave',
  moov: 'paymentMethod.moov',
  card: 'paymentMethod.card',
};
