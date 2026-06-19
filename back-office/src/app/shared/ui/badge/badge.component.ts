import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import type { StatusTone } from '@app/core/constants/order-status.constants';

const TONES: Record<StatusTone, string> = {
  neutral: 'bg-ink-100 text-ink-700 ring-ink-200',
  info: 'bg-blue-50 text-blue-700 ring-blue-200',
  warning: 'bg-amber-50 text-amber-700 ring-amber-200',
  success: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  danger: 'bg-red-50 text-red-700 ring-red-200',
  accent: 'bg-accent-50 text-accent-700 ring-accent-200',
};

/** Badge de statut coloré (libellé via clé i18n). */
@Component({
  selector: 'kz-badge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <span [class]="classes()">
      <span class="h-1.5 w-1.5 rounded-full bg-current opacity-70" aria-hidden="true"></span>
      {{ labelKey() | translate }}
    </span>
  `,
})
export class BadgeComponent {
  readonly tone = input<StatusTone>('neutral');
  readonly labelKey = input.required<string>();

  protected readonly classes = computed(
    () =>
      'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ring-1 ring-inset ' +
      TONES[this.tone()],
  );
}
