import type { OrderStatus } from '@app/core/constants/order-status.constants';
import type { PaymentMethod, PaymentStatus } from '@app/core/constants/payment-status.constants';

/** Adresse de livraison rattachée à une commande (spec : AddressDto/shippingAddress). */
export interface OrderAddress {
  readonly label?: string;
  readonly fullName: string;
  readonly phoneNumber: string;
  readonly line1: string;
  readonly line2?: string;
  readonly city: string;
  readonly region?: string;
  readonly country: string;
  readonly landmark?: string;
}

/** Ligne de commande (spec : OrderItemDto). */
export interface OrderItemDto {
  readonly id: string;
  readonly productName: string;
  readonly variantLabel: string;
  readonly sku: string;
  readonly imageUrl?: string;
  readonly unitPrice: number;
  readonly quantity: number;
  readonly lineTotal: number;
}

/** Paiement rattaché (spec : PaymentDto). */
export interface PaymentDto {
  readonly reference: string;
  readonly provider: string;
  readonly status: PaymentStatus;
  readonly amount: number;
  readonly currency: string;
  readonly paymentMethod?: PaymentMethod;
  readonly checkoutUrl?: string;
}

/**
 * Résumé de commande côté admin (spec : AdminOrderSummaryDto).
 * Étend le résumé client avec les infos client.
 */
export interface AdminOrderSummaryDto {
  readonly id: string;
  readonly orderNumber: string;
  readonly status: OrderStatus;
  readonly total: number;
  readonly currency: string;
  readonly itemCount: number;
  readonly customerName?: string;
  readonly customerEmail?: string;
  readonly placedAt: string;
}

/** Détail de commande côté admin (spec : AdminOrderDto). */
export interface AdminOrderDto {
  readonly id: string;
  readonly orderNumber: string;
  readonly status: OrderStatus;
  readonly subtotal: number;
  readonly shippingFee: number;
  readonly discount: number;
  readonly total: number;
  readonly currency: string;
  readonly items: OrderItemDto[];
  readonly shippingAddress: OrderAddress;
  readonly customerNote?: string;
  readonly customerId?: string;
  readonly customerName?: string;
  readonly customerEmail?: string;
  readonly customerPhone?: string;
  readonly payment?: PaymentDto;
  readonly placedAt: string;
  readonly paidAt?: string;
  readonly shippedAt?: string;
  readonly deliveredAt?: string;
  readonly cancelledAt?: string;
}

/** Body du changement de statut (spec : PUT /orders/{id}/status). */
export interface UpdateOrderStatusRequest {
  status: OrderStatus;
}

/** Filtres de la liste des commandes admin (spec : query status,search,page,pageSize). */
export interface AdminOrderQuery {
  status?: OrderStatus;
  search?: string;
  page?: number;
  pageSize?: number;
}
