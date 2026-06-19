import { Pipe, PipeTransform, inject } from '@angular/core';
import { I18nService } from './i18n.service';
import { formatDate } from '@app/core/utils/format.util';

/** `{{ isoString | localizedDate }}` — date/heure localisée selon la locale active. */
@Pipe({ name: 'localizedDate', pure: false })
export class LocalizedDatePipe implements PipeTransform {
  private readonly i18n = inject(I18nService);

  transform(value: string | null | undefined): string {
    return formatDate(value, this.i18n.locale());
  }
}
