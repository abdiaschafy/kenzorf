import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { I18nService } from '@app/core/services/i18n/i18n.service';
import { TranslatePipe } from '@app/core/services/i18n/translate.pipe';
import type { AppLocale } from '@app/core/constants/i18n.constants';

/** Sélecteur de langue (segmented control fr/en). */
@Component({
  selector: 'kz-language-switcher',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  template: `
    <div
      class="inline-flex items-center rounded-lg border border-ink-200 bg-white p-0.5"
      role="group"
      [attr.aria-label]="'lang.switch' | translate"
    >
      @for (loc of i18n.locales; track loc) {
        <button
          type="button"
          class="rounded-md px-2.5 py-1 text-xs font-medium uppercase transition-colors"
          [class]="i18n.locale() === loc ? 'bg-ink-950 text-white' : 'text-ink-500 hover:text-ink-900'"
          [attr.aria-pressed]="i18n.locale() === loc"
          (click)="select(loc)"
        >
          {{ loc }}
        </button>
      }
    </div>
  `,
})
export class LanguageSwitcherComponent {
  protected readonly i18n = inject(I18nService);

  protected select(locale: AppLocale): void {
    this.i18n.setLocale(locale);
  }
}
