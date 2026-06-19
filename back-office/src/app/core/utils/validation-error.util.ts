/** Forme minimale d'une erreur de validation Signal Forms exploitée par l'UI. */
export interface UiValidationError {
  readonly kind: string;
  readonly message?: string;
  readonly minLength?: number;
  readonly min?: number;
}

/** Mappe le `kind` d'une erreur Signal Forms vers une clé i18n. */
const KIND_TO_KEY: Record<string, string> = {
  required: 'validation.required',
  email: 'validation.email',
  minLength: 'validation.minLength',
  maxLength: 'validation.pattern',
  min: 'validation.min',
  max: 'validation.min',
  pattern: 'validation.pattern',
};

export interface MappedError {
  readonly key: string;
  readonly params?: Record<string, string | number>;
}

/** Renvoie la clé i18n (+ params) de la première erreur, ou null. */
export function firstErrorKey(errors: readonly UiValidationError[] | null | undefined): MappedError | null {
  if (!errors || errors.length === 0) {
    return null;
  }
  const err = errors[0];
  const key = KIND_TO_KEY[err.kind] ?? 'validation.pattern';
  const params: Record<string, string | number> = {};
  if (err.minLength !== undefined) {
    params['min'] = err.minLength;
  }
  if (err.min !== undefined) {
    params['min'] = err.min;
  }
  return { key, params };
}
