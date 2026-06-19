import type { AppLocale } from '@app/core/constants/i18n.constants';

const LOCALE_TAG: Record<AppLocale, string> = {
  fr: 'fr-FR',
  en: 'en-US',
};

/**
 * Formate un montant entier en FCFA (XOF), sans décimales.
 * Ex. 1500 → « 1 500 FCFA » (fr) / « 1,500 FCFA » (en).
 */
export function formatMoney(amount: number | null | undefined, locale: AppLocale, currency = 'XOF'): string {
  const value = amount ?? 0;
  const formatted = new Intl.NumberFormat(LOCALE_TAG[locale], {
    maximumFractionDigits: 0,
  }).format(value);
  return currency === 'XOF' ? `${formatted} FCFA` : `${formatted} ${currency}`;
}

/** Formate une date ISO en date courte localisée. */
export function formatDate(iso: string | null | undefined, locale: AppLocale): string {
  if (!iso) {
    return '—';
  }
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return '—';
  }
  return new Intl.DateTimeFormat(LOCALE_TAG[locale], {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

/** Génère un slug à partir d'un nom (fallback côté client). */
export function slugify(input: string): string {
  return input
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)+/g, '');
}
