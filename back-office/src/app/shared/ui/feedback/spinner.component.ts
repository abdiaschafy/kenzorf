import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';

/** Indicateur de chargement centré. */
@Component({
  selector: 'kz-spinner',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <div class="flex flex-col items-center justify-center gap-3 py-12 text-ink-400" role="status">
      <svg [class]="svgClasses()" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <circle class="opacity-20" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3"></circle>
        <path class="opacity-80" fill="currentColor" d="M4 12a8 8 0 018-8v3a5 5 0 00-5 5H4z"></path>
      </svg>
      <span class="text-sm">{{ labelKey() | translate }}</span>
    </div>
  `,
})
export class SpinnerComponent {
  readonly labelKey = input<string>('common.loading');
  readonly size = input<'sm' | 'md' | 'lg'>('md');

  protected readonly svgClasses = computed(() => {
    const sizes = { sm: 'h-5 w-5', md: 'h-8 w-8', lg: 'h-10 w-10' };
    return `${sizes[this.size()]} animate-spin text-ink-500`;
  });
}
