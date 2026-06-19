/** Type visuel d'une notification toast. */
export type ToastTone = 'success' | 'error' | 'info';

/** Notification affichée transitoirement (clé i18n, pas de texte en dur). */
export interface Toast {
  readonly id: number;
  readonly tone: ToastTone;
  readonly messageKey: string;
  readonly params?: Record<string, string | number>;
}
