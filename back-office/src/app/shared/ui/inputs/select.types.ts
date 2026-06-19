/** Option de liste déroulante (le libellé est une clé i18n ou un texte déjà localisé). */
export interface SelectOption {
  readonly value: string;
  readonly labelKey: string;
  /** Si vrai, `labelKey` est traité comme texte brut (déjà localisé, ex. nom de catégorie). */
  readonly rawLabel?: boolean;
}
