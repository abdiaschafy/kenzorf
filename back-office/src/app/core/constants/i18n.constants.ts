/** Locales supportées par le back-office KENZORF. */
export const APP_LOCALES = ['fr', 'en'] as const;
export type AppLocale = (typeof APP_LOCALES)[number];

export const DEFAULT_LOCALE: AppLocale = 'fr';

/** Clé de persistance de la locale choisie. */
export const LOCALE_STORAGE_KEY = 'kenzorf.admin.locale';
