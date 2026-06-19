import { Pipe, PipeTransform, inject } from '@angular/core';
import { I18nService, type TranslateParams } from './i18n.service';
import type { TranslationKey } from './locales/fr';

/**
 * Pipe de traduction : `{{ 'namespace.key' | translate }}`
 * ou `{{ 'key' | translate: { name: value } }}`.
 *
 * Impure pour refléter immédiatement le changement de locale (lookup O(1),
 * coût négligeable à l'échelle du back-office).
 */
@Pipe({ name: 'translate', pure: false })
export class TranslatePipe implements PipeTransform {
  private readonly i18n = inject(I18nService);

  transform(key: TranslationKey | string, params?: TranslateParams): string {
    return this.i18n.t(key as TranslationKey, params);
  }
}
