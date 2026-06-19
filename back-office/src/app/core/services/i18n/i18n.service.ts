import { Injectable, computed, signal } from '@angular/core';
import {
  APP_LOCALES,
  DEFAULT_LOCALE,
  LOCALE_STORAGE_KEY,
  type AppLocale,
} from '@app/core/constants/i18n.constants';
import { fr, type TranslationDictionary, type TranslationKey } from './locales/fr';
import { en } from './locales/en';

const DICTIONARIES: Record<AppLocale, TranslationDictionary> = { fr, en };

/** Paramètres d'interpolation `{name}`. */
export type TranslateParams = Record<string, string | number>;

@Injectable({ providedIn: 'root' })
export class I18nService {
  private readonly _locale = signal<AppLocale>(this.resolveInitialLocale());

  /** Locale courante (signal lisible). */
  readonly locale = this._locale.asReadonly();

  /** Locales disponibles. */
  readonly locales = APP_LOCALES;

  /** Dictionnaire courant (réactif). */
  private readonly dictionary = computed<TranslationDictionary>(() => DICTIONARIES[this._locale()]);

  /** Change la locale active et la persiste. */
  setLocale(locale: AppLocale): void {
    if (!APP_LOCALES.includes(locale)) {
      return;
    }
    this._locale.set(locale);
    try {
      localStorage.setItem(LOCALE_STORAGE_KEY, locale);
    } catch {
      // localStorage indisponible : on ignore silencieusement.
    }
    document.documentElement.lang = locale;
  }

  /**
   * Traduit une clé avec interpolation optionnelle.
   * Retourne la clé si elle est absente (visible en dev, jamais bloquant).
   */
  t(key: TranslationKey, params?: TranslateParams): string {
    const template = this.dictionary()[key] ?? key;
    return params ? this.interpolate(template, params) : template;
  }

  private interpolate(template: string, params: TranslateParams): string {
    return template.replace(/\{(\w+)\}/g, (match, name: string) => {
      const value = params[name];
      return value === undefined ? match : String(value);
    });
  }

  private resolveInitialLocale(): AppLocale {
    let stored: string | null = null;
    try {
      stored = localStorage.getItem(LOCALE_STORAGE_KEY);
    } catch {
      stored = null;
    }
    if (stored && (APP_LOCALES as readonly string[]).includes(stored)) {
      return stored as AppLocale;
    }
    return DEFAULT_LOCALE;
  }
}

export type { TranslationKey };
