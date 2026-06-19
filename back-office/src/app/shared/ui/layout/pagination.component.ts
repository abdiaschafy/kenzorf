import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';

/** Pagination simple précédent / suivant + indicateur de page. */
@Component({
  selector: 'kz-pagination',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    @if (totalPages() > 1) {
      <nav class="flex items-center justify-between gap-4 px-1 py-3" [attr.aria-label]="'common.page' | translate">
        <p class="text-xs text-ink-400">
          {{ 'common.page' | translate }} {{ page() }} {{ 'common.of' | translate }} {{ totalPages() }}
          · {{ total() }} {{ 'common.results' | translate }}
        </p>
        <div class="flex items-center gap-2">
          <button
            type="button"
            class="rounded-lg border border-ink-200 px-3 py-1.5 text-sm text-ink-700 hover:bg-ink-50 disabled:opacity-40 disabled:cursor-not-allowed"
            [disabled]="page() <= 1"
            (click)="goTo(page() - 1)"
          >
            {{ 'common.previous' | translate }}
          </button>
          <button
            type="button"
            class="rounded-lg border border-ink-200 px-3 py-1.5 text-sm text-ink-700 hover:bg-ink-50 disabled:opacity-40 disabled:cursor-not-allowed"
            [disabled]="page() >= totalPages()"
            (click)="goTo(page() + 1)"
          >
            {{ 'common.next' | translate }}
          </button>
        </div>
      </nav>
    }
  `,
})
export class PaginationComponent {
  readonly page = input.required<number>();
  readonly totalPages = input.required<number>();
  readonly total = input<number>(0);
  readonly pageChange = output<number>();

  protected readonly clamp = computed(() => Math.max(1, this.totalPages()));

  protected goTo(target: number): void {
    if (target >= 1 && target <= this.totalPages()) {
      this.pageChange.emit(target);
    }
  }
}
