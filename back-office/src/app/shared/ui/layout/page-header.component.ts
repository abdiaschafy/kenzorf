import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';

/** En-tête de page : titre + sous-titre (clés i18n) et zone d'actions à droite. */
@Component({
  selector: 'kz-page-header',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <div class="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="font-display text-2xl font-semibold tracking-tight text-ink-950">
          {{ titleKey() | translate }}
        </h1>
        @if (subtitleKey()) {
          <p class="mt-1 text-sm text-ink-400">{{ subtitleKey()! | translate }}</p>
        }
      </div>
      <div class="flex items-center gap-2">
        <ng-content />
      </div>
    </div>
  `,
})
export class PageHeaderComponent {
  readonly titleKey = input.required<string>();
  readonly subtitleKey = input<string>();
}
