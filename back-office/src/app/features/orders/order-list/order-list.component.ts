import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
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
import { EmptyStateComponent } from '@app/shared/ui/feedback/empty-state.component';
import { PaginationComponent } from '@app/shared/ui/layout/pagination.component';
import { OrderService } from '@app/core/services/order.service';
import {
  ORDER_STATUS_LABEL_KEY,
  ORDER_STATUS_TONE,
  ORDER_STATUS_VALUES,
  type OrderStatus,
} from '@app/core/constants/order-status.constants';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';

const PAGE_SIZE = 20;

@Component({
  selector: 'kz-order-list',
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
    EmptyStateComponent,
    PaginationComponent,
  ],
  template: `
    <kz-page-header titleKey="orders.title" subtitleKey="orders.subtitle" />

    <kz-card [bodyPadding]="false">
      <div class="flex flex-col gap-3 border-b border-ink-100 p-3 sm:flex-row sm:items-center">
        <input
          type="search"
          [value]="search()"
          [placeholder]="'orders.searchPlaceholder' | translate"
          class="h-9 w-full max-w-xs rounded-lg border border-ink-200 px-3 text-sm focus:border-ink-400 focus:outline-none focus:ring-2 focus:ring-accent-300"
          (input)="onSearch($event)"
        />
        <select
          [value]="status() ?? ''"
          class="h-9 rounded-lg border border-ink-200 px-3 text-sm focus:border-ink-400 focus:outline-none focus:ring-2 focus:ring-accent-300"
          [attr.aria-label]="'orders.filter.status' | translate"
          (change)="onStatus($event)"
        >
          <option value="">{{ 'common.all' | translate }}</option>
          @for (s of statuses; track s) {
            <option [value]="s">{{ labelFor(s) | translate }}</option>
          }
        </select>
      </div>

      @if (resource.isLoading()) {
        <kz-spinner />
      } @else if (resource.status() === 'error') {
        <kz-error-state (retry)="resource.reload()" />
      } @else if ((resource.value()?.items ?? []).length === 0) {
        <kz-empty-state titleKey="orders.empty.title" descriptionKey="orders.empty.description" />
      } @else {
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-ink-100 text-left text-xs uppercase tracking-wide text-ink-400">
                <th class="px-4 py-3 font-medium">{{ 'orders.col.number' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'orders.col.customer' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'orders.col.status' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'orders.col.items' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'orders.col.total' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'orders.col.date' | translate }}</th>
              </tr>
            </thead>
            <tbody>
              @for (order of resource.value()?.items ?? []; track order.id) {
                <tr class="cursor-pointer border-b border-ink-50 last:border-0 hover:bg-ink-50/60">
                  <td class="px-4 py-3">
                    <a [routerLink]="['/', segments.Orders, order.id]" class="font-medium text-ink-900 hover:underline">
                      {{ order.orderNumber }}
                    </a>
                  </td>
                  <td class="px-4 py-3 text-ink-700">
                    {{ order.customerName ?? order.customerEmail ?? '—' }}
                  </td>
                  <td class="px-4 py-3">
                    <kz-badge [tone]="toneFor(order.status)" [labelKey]="labelFor(order.status)" />
                  </td>
                  <td class="px-4 py-3 text-ink-700">{{ order.itemCount }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ order.total | money: order.currency }}</td>
                  <td class="px-4 py-3 text-ink-500">{{ order.placedAt | localizedDate }}</td>
                </tr>
              }
            </tbody>
          </table>
        </div>

        @if (resource.value(); as paged) {
          <div class="border-t border-ink-100 px-2">
            <kz-pagination
              [page]="paged.page"
              [totalPages]="paged.totalPages"
              [total]="paged.total"
              (pageChange)="page.set($event)"
            />
          </div>
        }
      }
    </kz-card>
  `,
})
export class OrderListComponent {
  private readonly orderService = inject(OrderService);

  protected readonly segments = ROUTE_SEGMENT;
  protected readonly statuses = ORDER_STATUS_VALUES;

  protected readonly search = signal('');
  protected readonly status = signal<OrderStatus | null>(null);
  protected readonly page = signal(1);

  private readonly query = computed(() => ({
    search: this.search().trim() || undefined,
    status: this.status() ?? undefined,
    page: this.page(),
    pageSize: PAGE_SIZE,
  }));

  protected readonly resource = rxResource({
    params: () => this.query(),
    stream: ({ params }) => this.orderService.list(params),
  });

  protected toneFor(status: OrderStatus) {
    return ORDER_STATUS_TONE[status];
  }

  protected labelFor(status: OrderStatus): string {
    return ORDER_STATUS_LABEL_KEY[status];
  }

  protected onSearch(event: Event): void {
    this.search.set((event.target as HTMLInputElement).value);
    this.page.set(1);
  }

  protected onStatus(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    this.status.set(value ? (value as OrderStatus) : null);
    this.page.set(1);
  }
}
