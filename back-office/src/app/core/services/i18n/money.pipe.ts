import { Pipe, PipeTransform, inject } from '@angular/core';
import { I18nService } from './i18n.service';
import { formatMoney } from '@app/core/utils/format.util';

/** `{{ amount | money }}` ou `{{ amount | money: currency }}` (FCFA par défaut). */
@Pipe({ name: 'money', pure: false })
export class MoneyPipe implements PipeTransform {
  private readonly i18n = inject(I18nService);

  transform(amount: number | null | undefined, currency = 'XOF'): string {
    return formatMoney(amount, this.i18n.locale(), currency);
  }
}
