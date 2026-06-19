/** Modèle local du formulaire catégorie (hors composant). */
export interface CategoryFormModel {
  name: string;
  slug: string;
  description: string;
  imageUrl: string;
  displayOrder: number | null;
  isActive: boolean;
}

export function emptyCategoryForm(): CategoryFormModel {
  return { name: '', slug: '', description: '', imageUrl: '', displayOrder: 0, isActive: true };
}
