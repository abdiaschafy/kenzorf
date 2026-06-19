import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';

/** État vide réutilisable (titre + description via clés i18n, slot actions). */
@Component({
  selector: 'kz-empty-state',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <div class="flex flex-col items-center justify-center gap-2 px-6 py-16 text-center">
      <div class="mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-ink-100 text-ink-400">
        <svg class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
        </svg>
      </div>
      <h3 class="text-sm font-semibold text-ink-900">{{ titleKey() | translate }}</h3>
      @if (descriptionKey()) {
        <p class="max-w-sm text-sm text-ink-400">{{ descriptionKey()! | translate }}</p>
      }
      <div class="mt-3">
        <ng-content />
      </div>
    </div>
  `,
})
export class EmptyStateComponent {
  readonly titleKey = input.required<string>();
  readonly descriptionKey = input<string>();
}
