import type { OrderStatus } from '@app/core/constants/order-status.constants';
import type { AdminOrderSummaryDto } from './order.interfaces';

/** Variante en stock bas (API : LowStockVariantDto). */
export interface LowStockVariantDto {
  readonly variantId: string;
  readonly productId: string;
  readonly productName: string;
  readonly sku: string;
  readonly variantLabel: string;
  readonly stockQuantity: number;
}

/** Tableau de bord admin (spec : DashboardDto). */
export interface DashboardDto {
  readonly revenueTotal: number;
  readonly revenueThisMonth: number;
  readonly currency: string;
  readonly ordersByStatus: Partial<Record<OrderStatus, number>>;
  readonly recentOrders: AdminOrderSummaryDto[];
  readonly lowStockVariants: LowStockVariantDto[];
}
