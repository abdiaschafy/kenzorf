import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { rxResource } from '@angular/core/rxjs-interop';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { MoneyPipe } from '@app/core/services/i18n/money.pipe';
import { LocalizedDatePipe } from '@app/core/services/i18n/localized-date.pipe';
import { PageHeaderComponent } from '@app/shared/ui/layout/page-header.component';
import { CardComponent } from '@app/shared/ui/card/card.component';
import { BadgeComponent } from '@app/shared/ui/badge/badge.component';
import { SpinnerComponent } from '@app/shared/ui/feedback/spinner.component';
import { ErrorStateComponent } from '@app/shared/ui/feedback/error-state.component';
import { DashboardService } from '@app/core/services/dashboard.service';
import {
  ORDER_STATUS_LABEL_KEY,
  ORDER_STATUS_TONE,
  ORDER_STATUS_VALUES,
  type OrderStatus,
} from '@app/core/constants/order-status.constants';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import { DEFAULT_CURRENCY } from '@app/core/constants/catalog.constants';

@Component({
  selector: 'kz-dashboard',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    RouterLink,
    TranslatePipe,
    MoneyPipe,
    LocalizedDatePipe,
    PageHeaderComponent,
    CardComponent,
    BadgeComponent,
    SpinnerComponent,
    ErrorStateComponent,
  ],
  template: `
    <kz-page-header titleKey="dashboard.title" subtitleKey="dashboard.subtitle" />

    @if (resource.isLoading()) {
      <kz-spinner />
    } @else if (resource.status() === 'error') {
      <kz-error-state (retry)="resource.reload()" />
    } @else if (resource.value(); as data) {
      <!-- KPIs -->
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <kz-card>
          <p class="text-xs font-medium uppercase tracking-wide text-ink-400">
            {{ 'dashboard.revenueTotal' | translate }}
          </p>
          <p class="mt-2 text-2xl font-semibold text-ink-950">{{ data.revenueTotal | money: data.currency }}</p>
        </kz-card>
        <kz-card>
          <p class="text-xs font-medium uppercase tracking-wide text-ink-400">
            {{ 'dashboard.revenueThisMonth' | translate }}
          </p>
          <p class="mt-2 text-2xl font-semibold text-ink-950">{{ data.revenueThisMonth | money: data.currency }}</p>
        </kz-card>
        <kz-card>
          <p class="text-xs font-medium uppercase tracking-wide text-ink-400">
            {{ 'dashboard.ordersCount' | translate }}
          </p>
          <p class="mt-2 text-2xl font-semibold text-ink-950">{{ totalOrders() }}</p>
        </kz-card>
        <kz-card>
          <p class="text-xs font-medium uppercase tracking-wide text-ink-400">
            {{ 'dashboard.lowStockCount' | translate }}
          </p>
          <p class="mt-2 text-2xl font-semibold" [class]="data.lowStockVariants.length ? 'text-red-600' : 'text-ink-950'">
            {{ data.lowStockVariants.length }}
          </p>
        </kz-card>
      </div>

      <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-3">
        <!-- Statuts -->
        <kz-card class="lg:col-span-1" titleKey="dashboard.ordersByStatus">
          <ul class="space-y-2.5">
            @for (row of statusRows(); track row.status) {
              <li class="flex items-center justify-between">
                <kz-badge [tone]="row.tone" [labelKey]="row.labelKey" />
                <span class="text-sm font-semibold text-ink-900">{{ row.count }}</span>
              </li>
            }
          </ul>
        </kz-card>

        <!-- Commandes récentes -->
        <kz-card class="lg:col-span-2" titleKey="dashboard.recentOrders">
          <a
            card-actions
            [routerLink]="ordersLink"
            class="text-xs font-medium text-accent-700 hover:underline"
          >
            {{ 'dashboard.viewAllOrders' | translate }}
          </a>
          @if (data.recentOrders.length === 0) {
            <p class="py-6 text-center text-sm text-ink-400">{{ 'dashboard.noRecentOrders' | translate }}</p>
          } @else {
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="border-b border-ink-100 text-left text-xs uppercase tracking-wide text-ink-400">
                    <th class="py-2 pr-3 font-medium">{{ 'orders.col.number' | translate }}</th>
                    <th class="py-2 pr-3 font-medium">{{ 'orders.col.status' | translate }}</th>
                    <th class="py-2 pr-3 font-medium">{{ 'orders.col.total' | translate }}</th>
                    <th class="py-2 font-medium">{{ 'orders.col.date' | translate }}</th>
                  </tr>
                </thead>
                <tbody>
                  @for (order of data.recentOrders; track order.id) {
                    <tr class="border-b border-ink-50 last:border-0">
                      <td class="py-2.5 pr-3 font-medium text-ink-900">{{ order.orderNumber }}</td>
                      <td class="py-2.5 pr-3">
                        <kz-badge [tone]="toneFor(order.status)" [labelKey]="labelFor(order.status)" />
                      </td>
                      <td class="py-2.5 pr-3 text-ink-700">{{ order.total | money: order.currency }}</td>
                      <td class="py-2.5 text-ink-500">{{ order.placedAt | localizedDate }}</td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          }
        </kz-card>
      </div>

      <!-- Stock bas -->
      <div class="mt-6">
        <kz-card titleKey="dashboard.lowStock">
          @if (data.lowStockVariants.length === 0) {
            <p class="py-4 text-center text-sm text-ink-400">{{ 'dashboard.lowStock.empty' | translate }}</p>
          } @else {
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="border-b border-ink-100 text-left text-xs uppercase tracking-wide text-ink-400">
                    <th class="py-2 pr-3 font-medium">{{ 'products.col.product' | translate }}</th>
                    <th class="py-2 pr-3 font-medium">{{ 'productForm.variant.sku' | translate }}</th>
                    <th class="py-2 pr-3 font-medium">{{ 'dashboard.lowStock.variant' | translate }}</th>
                    <th class="py-2 font-medium">{{ 'products.col.stock' | translate }}</th>
                  </tr>
                </thead>
                <tbody>
                  @for (v of data.lowStockVariants; track v.variantId) {
                    <tr class="border-b border-ink-50 last:border-0">
                      <td class="py-2.5 pr-3 font-medium text-ink-900">{{ v.productName }}</td>
                      <td class="py-2.5 pr-3 font-mono text-xs text-ink-500">{{ v.sku }}</td>
                      <td class="py-2.5 pr-3 text-ink-700">{{ v.variantLabel }}</td>
                      <td class="py-2.5">
                        <span class="font-semibold text-red-600">{{ v.stockQuantity }}</span>
                      </td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          }
        </kz-card>
      </div>
    }
  `,
})
export class DashboardComponent {
  private readonly dashboardService = inject(DashboardService);

  protected readonly ordersLink = `/${ROUTE_SEGMENT.Orders}`;

  protected readonly resource = rxResource({
    stream: () => this.dashboardService.getDashboard(),
  });

  protected readonly totalOrders = computed(() => {
    const data = this.resource.value();
    if (!data) {
      return 0;
    }
    return Object.values(data.ordersByStatus).reduce((sum, n) => sum + (n ?? 0), 0);
  });

  protected readonly statusRows = computed(() => {
    const data = this.resource.value();
    const counts = data?.ordersByStatus ?? {};
    return ORDER_STATUS_VALUES.map((status) => ({
      status,
      labelKey: ORDER_STATUS_LABEL_KEY[status],
      tone: ORDER_STATUS_TONE[status],
      count: counts[status] ?? 0,
    }));
  });

  protected toneFor(status: OrderStatus) {
    return ORDER_STATUS_TONE[status];
  }

  protected labelFor(status: OrderStatus): string {
    return ORDER_STATUS_LABEL_KEY[status];
  }

  protected readonly defaultCurrency = DEFAULT_CURRENCY;
}
