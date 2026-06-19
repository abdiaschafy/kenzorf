import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { rxResource } from '@angular/core/rxjs-interop';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { MoneyPipe } from '@app/core/services/i18n/money.pipe';
import { LocalizedDatePipe } from '@app/core/services/i18n/localized-date.pipe';
import { PageHeaderComponent } from '@app/shared/ui/layout/page-header.component';
import { CardComponent } from '@app/shared/ui/card/card.component';
import { SpinnerComponent } from '@app/shared/ui/feedback/spinner.component';
import { ErrorStateComponent } from '@app/shared/ui/feedback/error-state.component';
import { EmptyStateComponent } from '@app/shared/ui/feedback/empty-state.component';
import { PaginationComponent } from '@app/shared/ui/layout/pagination.component';
import { CustomerService } from '@app/core/services/customer.service';

const PAGE_SIZE = 20;

@Component({
  selector: 'kz-customers',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    TranslatePipe,
    MoneyPipe,
    LocalizedDatePipe,
    PageHeaderComponent,
    CardComponent,
    SpinnerComponent,
    ErrorStateComponent,
    EmptyStateComponent,
    PaginationComponent,
  ],
  template: `
    <kz-page-header titleKey="customers.title" subtitleKey="customers.subtitle" />

    <kz-card [bodyPadding]="false">
      <div class="border-b border-ink-100 p-3">
        <input
          type="search"
          [value]="search()"
          [placeholder]="'common.searchPlaceholder' | translate"
          class="h-9 w-full max-w-xs rounded-lg border border-ink-200 px-3 text-sm focus:border-ink-400 focus:outline-none focus:ring-2 focus:ring-accent-300"
          (input)="onSearch($event)"
        />
      </div>

      @if (resource.isLoading()) {
        <kz-spinner />
      } @else if (resource.status() === 'error') {
        <kz-error-state (retry)="resource.reload()" />
      } @else if ((resource.value()?.items ?? []).length === 0) {
        <kz-empty-state titleKey="customers.empty.title" descriptionKey="customers.empty.description" />
      } @else {
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-ink-100 text-left text-xs uppercase tracking-wide text-ink-400">
                <th class="px-4 py-3 font-medium">{{ 'customers.col.name' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'customers.col.email' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'customers.col.phone' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'customers.col.orders' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'customers.col.spent' | translate }}</th>
                <th class="px-4 py-3 font-medium">{{ 'customers.col.since' | translate }}</th>
              </tr>
            </thead>
            <tbody>
              @for (customer of resource.value()?.items ?? []; track customer.id) {
                <tr class="border-b border-ink-50 last:border-0 hover:bg-ink-50/60">
                  <td class="px-4 py-3">
                    <div class="flex items-center gap-3">
                      <div class="flex h-8 w-8 items-center justify-center rounded-full bg-ink-100 text-xs font-semibold text-ink-600" aria-hidden="true">
                        {{ initials(customer.firstName, customer.lastName) }}
                      </div>
                      <span class="font-medium text-ink-900">{{ customer.firstName }} {{ customer.lastName }}</span>
                    </div>
                  </td>
                  <td class="px-4 py-3 text-ink-700">{{ customer.email }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ customer.phoneNumber ?? '—' }}</td>
                  <td class="px-4 py-3 text-ink-700">{{ customer.orderCount ?? 0 }}</td>
                  <td class="px-4 py-3 text-ink-700">
                    {{ customer.totalSpent != null ? (customer.totalSpent | money: customer.currency ?? defaultCurrency) : '—' }}
                  </td>
                  <td class="px-4 py-3 text-ink-500">{{ customer.createdAt | localizedDate }}</td>
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
export class CustomersComponent {
  private readonly customerService = inject(CustomerService);

  protected readonly defaultCurrency = 'XOF';
  protected readonly search = signal('');
  protected readonly page = signal(1);

  private readonly query = computed(() => ({
    search: this.search().trim() || undefined,
    page: this.page(),
    pageSize: PAGE_SIZE,
  }));

  protected readonly resource = rxResource({
    params: () => this.query(),
    stream: ({ params }) => this.customerService.list(params),
  });

  protected initials(first: string, last: string): string {
    return `${first.charAt(0)}${last.charAt(0)}`.toUpperCase();
  }

  protected onSearch(event: Event): void {
    this.search.set((event.target as HTMLInputElement).value);
    this.page.set(1);
  }
}
