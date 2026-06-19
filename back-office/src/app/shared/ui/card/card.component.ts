import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';

/** Conteneur carte avec titre optionnel et zone d'actions (slot `[card-actions]`). */
@Component({
  selector: 'kz-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <section class="rounded-xl border border-ink-100 bg-white shadow-card">
      @if (titleKey() || hasHeader()) {
        <header class="flex items-center justify-between gap-3 border-b border-ink-100 px-5 py-4">
          <div>
            @if (titleKey()) {
              <h2 class="text-sm font-semibold text-ink-900">{{ titleKey()! | translate }}</h2>
            }
            @if (subtitleKey()) {
              <p class="mt-0.5 text-xs text-ink-400">{{ subtitleKey()! | translate }}</p>
            }
          </div>
          <ng-content select="[card-actions]" />
        </header>
      }
      <div [class]="bodyPadding() ? 'p-5' : ''">
        <ng-content />
      </div>
    </section>
  `,
})
export class CardComponent {
  readonly titleKey = input<string>();
  readonly subtitleKey = input<string>();
  readonly hasHeader = input<boolean>(false);
  readonly bodyPadding = input<boolean>(true);
}
