/** Enveloppe de pagination standard (spec §3). */
export interface Paged<T> {
  readonly items: T[];
  readonly page: number;
  readonly pageSize: number;
  readonly total: number;
  readonly totalPages: number;
}

/** Paramètres de pagination communs. */
export interface PageQuery {
  page?: number;
  pageSize?: number;
}

/** Format d'erreur standardisé renvoyé par l'API (spec §3). */
export interface ApiError {
  readonly code: string;
  readonly messageKey: string;
  readonly params?: Record<string, unknown>;
  readonly status: number;
}
