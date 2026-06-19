import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { rxResource } from '@angular/core/rxjs-interop';
import { firstValueFrom } from 'rxjs';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { MoneyPipe } from '@app/core/services/i18n/money.pipe';
import { PageHeaderComponent } from '@app/shared/ui/layout/page-header.component';
import { CardComponent } from '@app/shared/ui/card/card.component';
import { BadgeComponent } from '@app/shared/ui/badge/badge.component';
import { ButtonComponent } from '@app/shared/ui/button/button.component';
import { SpinnerComponent } from '@app/shared/ui/feedback/spinner.component';
import { ErrorStateComponent } from '@app/shared/ui/feedback/error-state.component';
import { EmptyStateComponent } from '@app/shared/ui/feedback/empty-state.component';
import { PaginationComponent } from '@app/shared/ui/layout/pagination.component';
import { ConfirmDialogComponent } from '@app/shared/ui/modal/confirm-dialog.component';
import { ProductService } from '@app/core/services/product.service';
import { NotificationService } from '@app/core/services/notification.service';
import { GENDER_LABEL_KEY } from '@app/core/constants/catalog.constants';
import { ROUTE_SEGMENT } from '@app/core/constants/routes.constants';
import type { AdminProductSummaryDto } from '@app/core/interfaces/admin-product.interfaces';
import type { Gender } from '@app/core/constants/catalog.constants';

const PAGE_SIZE = 20;

@Component({
  selector: 'kz-product-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    RouterLink,
    TranslatePipe,
    MoneyPipe,
    PageHeaderComponent,
    CardComponent,
    BadgeComponent,
    ButtonComponent,
    SpinnerComponent,
    ErrorStateComponent,
    EmptyStateComponent,
    PaginationComponent,
    ConfirmDialogComponent,
  ],
  template: `
    <kz-page-header titleKey="products.title" subtitleKey="products.subtitle">
      <a [routerLink]="newLink">
        <kz-button>
          <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" d="M12 5v14M5 12h14" />
          </svg>
          {{ 'products.new' | translate }}
        </kz-button>
      </a>
    </kz-page-header>

    <kz-card [bodyPadding]="false">
      <div class="border-b border-ink-100 p-3">
        <input
          type="search"
          [value]="search()"
          [placeholder]="'products.searchPlaceholder' | translate"
          class="h-9 w-full max-w-xs rounded-lg border border-ink-200 px-3 text-sm focus:border-ink-400 focus:outline-none focus:ring-2 focus:ring-accent-300"
          (input)="onSearch($event)"
        />
      </div>

      @if (resource.isLoading()) {
        <kz-spinner />
      } @else if (resource.status() === 'error') {
        <kz-error-state (retry)="resource.reload()" />
      } @else if ((resource.value()?.items ?? []).length === 0) {
        <kz-empty-state titleKey="products.empty.title" descriptionKey="products.empty.description">
          <a [routerLink]="newLink"><kz-button>{{ 'products.new' | translate }}</kz-button></a>
        </kz-empty-state>
      } @else {
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-ink-100 text-left text-xs uppercase tracking-wide text-ink-400">
                <th class="px-4 py-3 font-medium">{{ 'products.col.product' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'products.col.category' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'products.col.gender' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'products.col.price' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'products.col.variants' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'products.col.stock' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'products.col.status' | translate }}</th>
                <th class="px-4 py-3 text-right font-medium">{{ 'common.actions' | translate }}</th>
              </tr>
            </thead>
            <tbody>
              @for (product of resource.value()?.items ?? []; track product.id) {
                <tr class="border-b border-ink-50 last:border-0 hover:bg-ink-50/60">
                  <td class="px-4 py-3">
                    <div class="flex items-center gap-3">
                      <div class="h-10 w-10 shrink-0 overflow-hidden rounded-lg bg-ink-100">
                        @if (product.primaryImageUrl; as url) {
                          <img [src]="url" [alt]="product.name" class="h-full w-full object-cover" />
                        }
                      </div>
                      <div class="min-w-0">
                        <p class="truncate font-medium text-ink-900">{{ product.name }}</p>
                        <p class="truncate text-xs text-ink-400">{{ product.slug }}</p>
                      </div>
                    </div>
                  </td>
                  <td class="px-4 py-3 text-ink-700">{{ product.categoryName }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ genderLabel(product.gender) | translate }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ product.basePrice | money: product.currency }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ product.variantCount }}</td>
                  <td class="px-4 py-3">
                    <span [class]="product.totalStock > 0 ? 'text-ink-700' : 'text-red-600 font-medium'">
                      {{ product.totalStock }}
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <div class="flex flex-wrap items-center gap-1.5">
                      <kz-badge
                        [tone]="product.isActive ? 'success' : 'neutral'"
                        [labelKey]="product.isActive ? 'products.status.active' : 'products.status.inactive'"
                      />
                      @if (product.isFeatured) {
                        <kz-badge tone="accent" labelKey="products.featured" />
                      }
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <div class="flex items-center justify-end gap-2">
                      <a
                        [routerLink]="['/', segments.Products, product.id]"
                        class="rounded-lg p-1.5 text-ink-500 hover:bg-ink-100 hover:text-ink-900"
                        [attr.aria-label]="'common.edit' | translate"
                      >
                        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7m-1.5-9.5a2.12 2.12 0 013 3L12 16l-4 1 1-4 8.5-8.5z" />
                        </svg>
                      </a>
                      <button
                        type="button"
                        class="rounded-lg p-1.5 text-ink-500 hover:bg-red-50 hover:text-red-600"
                        [attr.aria-label]="'common.delete' | translate"
                        (click)="askDelete(product)"
                      >
                        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M3 6h18M8 6V4a1 1 0 011-1h6a1 1 0 011 1v2m2 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z" />
                        </svg>
                      </button>
                    </div>
                  </td>
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

    <kz-confirm-dialog
      [open]="!!pendingDelete()"
      titleKey="products.deleteConfirm.title"
      messageKey="products.deleteConfirm.message"
      [messageParams]="{ name: pendingDelete()?.name ?? '' }"
      confirmKey="common.delete"
      [danger]="true"
      [loading]="deleting()"
      (confirmed)="confirmDelete()"
      (cancelled)="pendingDelete.set(null)"
    />
  `,
})
export class ProductListComponent {
  private readonly productService = inject(ProductService);
  private readonly notifications = inject(NotificationService);

  protected readonly segments = ROUTE_SEGMENT;
  protected readonly newLink = `/${ROUTE_SEGMENT.Products}/${ROUTE_SEGMENT.New}`;

  protected readonly search = signal('');
  protected readonly page = signal(1);
  protected readonly pendingDelete = signal<AdminProductSummaryDto | null>(null);
  protected readonly deleting = signal(false);

  private readonly query = computed(() => ({
    search: this.search().trim() || undefined,
    page: this.page(),
    pageSize: PAGE_SIZE,
  }));

  protected readonly resource = rxResource({
    params: () => this.query(),
    stream: ({ params }) => this.productService.list(params),
  });

  protected genderLabel(gender: Gender): string {
    return GENDER_LABEL_KEY[gender];
  }

  protected onSearch(event: Event): void {
    this.search.set((event.target as HTMLInputElement).value);
    this.page.set(1);
  }

  protected askDelete(product: AdminProductSummaryDto): void {
    this.pendingDelete.set(product);
  }

  protected async confirmDelete(): Promise<void> {
    const product = this.pendingDelete();
    if (!product) {
      return;
    }
    this.deleting.set(true);
    try {
      await firstValueFrom(this.productService.remove(product.id));
      this.notifications.success('products.deleted');
      this.pendingDelete.set(null);
      this.resource.reload();
    } catch {
      this.notifications.error('error.unknown');
    } finally {
      this.deleting.set(false);
    }
  }
}
