import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import { ButtonComponent } from '@app/shared/ui/button/button.component';

/** État d'erreur réutilisable avec action « réessayer ». */
@Component({
  selector: 'kz-error-state',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, ButtonComponent],
  template: `
    <div class="flex flex-col items-center justify-center gap-2 px-6 py-16 text-center">
      <div class="mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-red-50 text-red-500">
        <svg class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v4m0 4h.01M10.3 3.86l-7.6 13.2A1.5 1.5 0 004 19.5h16a1.5 1.5 0 001.3-2.44l-7.6-13.2a1.5 1.5 0 00-2.6 0z" />
        </svg>
      </div>
      <h3 class="text-sm font-semibold text-ink-900">{{ titleKey() | translate }}</h3>
      <p class="max-w-sm text-sm text-ink-400">{{ messageKey() | translate }}</p>
      @if (retryable()) {
        <div class="mt-3">
          <kz-button variant="outline" size="sm" (click)="retry.emit()">
            {{ 'common.retry' | translate }}
          </kz-button>
        </div>
      }
    </div>
  `,
})
export class ErrorStateComponent {
  readonly titleKey = input<string>('state.error.title');
  readonly messageKey = input<string>('state.error.description');
  readonly retryable = input<boolean>(true);
  readonly retry = output<void>();
}
