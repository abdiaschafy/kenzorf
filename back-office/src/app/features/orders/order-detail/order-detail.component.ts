import { ChangeDetectionStrategy, Component, computed, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { rxResource } from '@angular/core/rxjs-interop';
import { firstValueFrom } from 'rxjs';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { MoneyPipe } from '@app/core/services/i18n/money.pipe';
import { LocalizedDatePipe } from '@app/core/services/i18n/localized-date.pipe';
import { PageHeaderComponent } from '@app/shared/ui/layout/page-header.component';
import { CardComponent } from '@app/shared/ui/card/card.component';
import { BadgeComponent } from '@app/shared/ui/badge/badge.component';
import { ButtonComponent } from '@app/shared/ui/button/button.component';
import { SpinnerComponent } from '@app/shared/ui/feedback/spinner.component';
import { ErrorStateComponent } from '@app/shared/ui/feedback/error-state.component';
import { OrderService } from '@app/core/services/order.service';
import { NotificationService } from '@app/core/services/notification.service';
import {
  ORDER_STATUS_LABEL_KEY,
  ORDER_STATUS_TONE,
  ORDER_STATUS_TRANSITIONS,
  type OrderStatus,
} from '@app/core/constants/order-status.constants';
import {
  PAYMENT_METHOD_LABEL_KEY,
  PAYMENT_STATUS_LABEL_KEY,
  PAYMENT_STATUS_TONE,
} from '@app/core/constants/payment-status.constants';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';

@Component({
  selector: 'kz-order-detail',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    RouterLink,
    TranslatePipe,
    MoneyPipe,
    LocalizedDatePipe,
    PageHeaderComponent,
    CardComponent,
    BadgeComponent,
    ButtonComponent,
    SpinnerComponent,
    ErrorStateComponent,
  ],
  template: `
    @if (resource.isLoading()) {
      <kz-spinner />
    } @else if (resource.status() === 'error') {
      <kz-error-state (retry)="resource.reload()" />
    } @else if (resource.value(); as order) {
      <kz-page-header [titleKey]="'orders.detail.title'" [subtitleKey]="undefined">
        <a [routerLink]="listLink" class="text-sm font-medium text-ink-500 hover:text-ink-900">
          ← {{ 'common.back' | translate }}
        </a>
      </kz-page-header>

      <div class="-mt-3 mb-6 flex items-center gap-3">
        <h2 class="font-display text-xl font-semibold text-ink-950">{{ order.orderNumber }}</h2>
        <kz-badge [tone]="toneFor(order.status)" [labelKey]="labelFor(order.status)" />
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <!-- Colonne principale -->
        <div class="space-y-6 lg:col-span-2">
          <kz-card titleKey="orders.detail.items" [bodyPadding]="false">
            <div class="divide-y divide-ink-50">
              @for (item of order.items; track item.id) {
                <div class="flex items-center gap-4 px-5 py-3">
                  <div class="h-12 w-12 shrink-0 overflow-hidden rounded-lg bg-ink-100">
                    @if (item.imageUrl) {
                      <img [src]="item.imageUrl" [alt]="item.productName" class="h-full w-full object-cover" />
                    }
                  </div>
                  <div class="min-w-0 flex-1">
                    <p class="truncate font-medium text-ink-900">{{ item.productName }}</p>
                    <p class="truncate text-xs text-ink-400">{{ item.variantLabel }} · {{ item.sku }}</p>
                  </div>
                  <div class="text-right">
                    <p class="text-sm text-ink-700">{{ item.unitPrice | money: order.currency }} × {{ item.quantity }}</p>
                    <p class="text-sm font-semibold text-ink-900">{{ item.lineTotal | money: order.currency }}</p>
                  </div>
                </div>
              }
            </div>
          </kz-card>

          @if (order.customerNote) {
            <kz-card titleKey="orders.detail.note">
              <p class="text-sm text-ink-600">{{ order.customerNote }}</p>
            </kz-card>
          }
        </div>

        <!-- Colonne latérale -->
        <div class="space-y-6">
          <!-- Récapitulatif -->
          <kz-card titleKey="orders.detail.summary">
            <dl class="space-y-2 text-sm">
              <div class="flex justify-between">
                <dt class="text-ink-500">{{ 'orders.detail.subtotal' | translate }}</dt>
                <dd class="text-ink-900">{{ order.subtotal | money: order.currency }}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-ink-500">{{ 'orders.detail.shippingFee' | translate }}</dt>
                <dd class="text-ink-900">{{ order.shippingFee | money: order.currency }}</dd>
              </div>
              @if (order.discount > 0) {
                <div class="flex justify-between">
                  <dt class="text-ink-500">{{ 'orders.detail.discount' | translate }}</dt>
                  <dd class="text-emerald-600">−{{ order.discount | money: order.currency }}</dd>
                </div>
              }
              <div class="flex justify-between border-t border-ink-100 pt-2 text-base font-semibold">
                <dt class="text-ink-900">{{ 'common.total' | translate }}</dt>
                <dd class="text-ink-950">{{ order.total | money: order.currency }}</dd>
              </div>
            </dl>
            <div class="mt-3 space-y-1 border-t border-ink-100 pt-3 text-xs text-ink-400">
              <p>{{ 'orders.detail.placedAt' | translate }} {{ order.placedAt | localizedDate }}</p>
              @if (order.paidAt) {
                <p>{{ 'orders.detail.paidAt' | translate }} {{ order.paidAt | localizedDate }}</p>
              }
              @if (order.shippedAt) {
                <p>{{ 'orders.detail.shippedAt' | translate }} {{ order.shippedAt | localizedDate }}</p>
              }
              @if (order.deliveredAt) {
                <p>{{ 'orders.detail.deliveredAt' | translate }} {{ order.deliveredAt | localizedDate }}</p>
              }
              @if (order.cancelledAt) {
                <p>{{ 'orders.detail.cancelledAt' | translate }} {{ order.cancelledAt | localizedDate }}</p>
              }
            </div>
          </kz-card>

          <!-- Changement de statut -->
          <kz-card titleKey="orders.detail.changeStatus">
            @if (transitions().length === 0) {
              <p class="text-sm text-ink-400">{{ 'orders.detail.noTransitions' | translate }}</p>
            } @else {
              <div class="space-y-3">
                <label class="block text-sm font-medium text-ink-700" [attr.for]="'status-select'">
                  {{ 'orders.detail.newStatus' | translate }}
                </label>
                <select
                  id="status-select"
                  [value]="targetStatus() ?? ''"
                  class="h-10 w-full rounded-lg border border-ink-200 px-3 text-sm focus:border-ink-400 focus:outline-none focus:ring-2 focus:ring-accent-300"
                  (change)="onSelectStatus($event)"
                >
                  <option value="" disabled>{{ 'orders.detail.newStatus' | translate }}</option>
                  @for (s of transitions(); track s) {
                    <option [value]="s">{{ labelFor(s) | translate }}</option>
                  }
                </select>
                <kz-button
                  [block]="true"
                  [disabled]="!targetStatus()"
                  [loading]="updating()"
                  (click)="applyStatus(order.id)"
                >
                  {{ 'orders.detail.applyStatus' | translate }}
                </kz-button>
              </div>
            }
          </kz-card>

          <!-- Client -->
          <kz-card titleKey="orders.detail.customer">
            <div class="space-y-1 text-sm">
              <p class="font-medium text-ink-900">{{ order.customerName ?? '—' }}</p>
              @if (order.customerEmail) {
                <p class="text-ink-500">{{ order.customerEmail }}</p>
              }
              @if (order.customerPhone) {
                <p class="text-ink-500">{{ order.customerPhone }}</p>
              }
            </div>
          </kz-card>

          <!-- Livraison -->
          <kz-card titleKey="orders.detail.shipping">
            <address class="space-y-0.5 text-sm not-italic text-ink-600">
              <p class="font-medium text-ink-900">{{ order.shippingAddress.fullName }}</p>
              <p>{{ order.shippingAddress.phoneNumber }}</p>
              <p>{{ order.shippingAddress.line1 }}</p>
              @if (order.shippingAddress.line2) {
                <p>{{ order.shippingAddress.line2 }}</p>
              }
              <p>{{ order.shippingAddress.city }}@if (order.shippingAddress.region) {, {{ order.shippingAddress.region }}}</p>
              <p>{{ order.shippingAddress.country }}</p>
              @if (order.shippingAddress.landmark) {
                <p class="text-ink-400">{{ order.shippingAddress.landmark }}</p>
              }
            </address>
          </kz-card>

          <!-- Paiement -->
          <kz-card titleKey="orders.detail.payment">
            @if (order.payment; as payment) {
              <dl class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <dt class="text-ink-500">{{ 'common.status' | translate }}</dt>
                  <dd><kz-badge [tone]="paymentTone(payment.status)" [labelKey]="paymentLabel(payment.status)" /></dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-ink-500">{{ 'orders.payment.reference' | translate }}</dt>
                  <dd class="font-mono text-xs text-ink-700">{{ payment.reference }}</dd>
                </div>
                <div class="flex justify-between">
                  <dt class="text-ink-500">{{ 'orders.payment.provider' | translate }}</dt>
                  <dd class="text-ink-700">{{ payment.provider }}</dd>
                </div>
                @if (payment.paymentMethod) {
                  <div class="flex justify-between">
                    <dt class="text-ink-500">{{ 'orders.payment.method' | translate }}</dt>
                    <dd class="text-ink-700">{{ paymentMethodLabel(payment.paymentMethod) | translate }}</dd>
                  </div>
                }
                <div class="flex justify-between">
                  <dt class="text-ink-500">{{ 'orders.payment.amount' | translate }}</dt>
                  <dd class="text-ink-900">{{ payment.amount | money: payment.currency }}</dd>
                </div>
              </dl>
            } @else {
              <p class="text-sm text-ink-400">{{ 'orders.payment.none' | translate }}</p>
            }
          </kz-card>
        </div>
      </div>
    }
  `,
})
export class OrderDetailComponent {
  private readonly orderService = inject(OrderService);
  private readonly notifications = inject(NotificationService);

  readonly id = input.required<string>();

  protected readonly listLink = `/${ROUTE_SEGMENT.Orders}`;

  protected readonly targetStatus = signal<OrderStatus | null>(null);
  protected readonly updating = signal(false);

  protected readonly resource = rxResource({
    params: () => this.id(),
    stream: ({ params }) => this.orderService.get(params),
  });

  protected readonly transitions = computed<readonly OrderStatus[]>(() => {
    const order = this.resource.value();
    return order ? ORDER_STATUS_TRANSITIONS[order.status] : [];
  });

  protected toneFor(status: OrderStatus) {
    return ORDER_STATUS_TONE[status];
  }

  protected labelFor(status: OrderStatus): string {
    return ORDER_STATUS_LABEL_KEY[status];
  }

  protected paymentTone(status: keyof typeof PAYMENT_STATUS_TONE) {
    return PAYMENT_STATUS_TONE[status];
  }

  protected paymentLabel(status: keyof typeof PAYMENT_STATUS_LABEL_KEY): string {
    return PAYMENT_STATUS_LABEL_KEY[status];
  }

  protected paymentMethodLabel(method: keyof typeof PAYMENT_METHOD_LABEL_KEY): string {
    return PAYMENT_METHOD_LABEL_KEY[method];
  }

  protected onSelectStatus(event: Event): void {
    const value = (event.target as HTMLSelectElement).value;
    this.targetStatus.set(value ? (value as OrderStatus) : null);
  }

  protected async applyStatus(orderId: string): Promise<void> {
    const status = this.targetStatus();
    if (!status) {
      return;
    }
    this.updating.set(true);
    try {
      await firstValueFrom(this.orderService.updateStatus(orderId, { status }));
      this.notifications.success('orders.statusUpdated');
      this.targetStatus.set(null);
      this.resource.reload();
    } catch {
      this.notifications.error('error.unknown');
    } finally {
      this.updating.set(false);
    }
  }
}
