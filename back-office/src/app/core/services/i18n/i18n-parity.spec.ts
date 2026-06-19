import { fr } from './locales/fr';
import { en } from './locales/en';

/** Garantit que les dictionnaires fr/en ont exactement les mêmes clés. */
describe('i18n parité fr/en', () => {
  const frKeys = Object.keys(fr).sort();
  const enKeys = Object.keys(en).sort();

  it('en ne manque aucune clé présente en fr', () => {
    const missing = frKeys.filter((k) => !(k in en));
    expect(missing).toEqual([]);
  });

  it('en ne contient aucune clé absente de fr', () => {
    const extra = enKeys.filter((k) => !(k in fr));
    expect(extra).toEqual([]);
  });

  it('aucune traduction vide', () => {
    const emptyFr = frKeys.filter((k) => !(fr as Record<string, string>)[k]?.trim());
    const emptyEn = enKeys.filter((k) => !(en as Record<string, string>)[k]?.trim());
    expect(emptyFr).toEqual([]);
    expect(emptyEn).toEqual([]);
  });
});
