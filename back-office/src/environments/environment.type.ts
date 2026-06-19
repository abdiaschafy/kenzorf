import type { AppLocale } from '@app/core/constants/i18n.constants';

export interface AppEnvironment {
  readonly production: boolean;
  readonly apiUrl: string;
  readonly defaultLocale: AppLocale;
}
