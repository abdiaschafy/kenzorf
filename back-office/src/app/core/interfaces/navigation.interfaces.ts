/** Élément de navigation latérale (libellé via clé i18n). */
export interface NavItem {
  readonly path: string;
  readonly labelKey: string;
  readonly icon: NavIcon;
}

/** Groupe d'items de navigation. */
export interface NavGroup {
  readonly labelKey: string;
  readonly items: readonly NavItem[];
}

/** Identifiants d'icônes (SVG inline mappés dans la sidebar). */
export type NavIcon = 'dashboard' | 'products' | 'categories' | 'orders' | 'customers';
