# Mémoire — angular-feature (back-office KENZORF)

## Environnement
- App : `back-office/` — **Angular 22.0.2**, **Node 22.22.3**, **TypeScript 6**, builder esbuild (`@angular/build`).
- **Zoneless par défaut** (pas de zone.js, pas de polyfills). `provideZonelessChangeDetection()` dans `app.config.ts`. → tout en signals + OnPush, mises à jour de state **immuables** (sinon pas de re-render).
- Avant tout `ng`/`npm` : `export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"`.
- Build : `npm run build` (OK). Tests : `npm test` (Vitest one-shot, ne pas passer `--no-watch`).
- TS 6 : **ne pas mettre `baseUrl`** (déprécié → erreur). Les `paths` se résolvent relativement au tsconfig : `"@app/*": ["./src/app/*"]`, `"@env/*": ["./src/environments/*"]`.

## Architecture en place (à réutiliser, ne pas recréer)
- `core/` : `interfaces/*.interfaces.ts` (alignés DTOs spec §5), `constants/*.constants.ts` (statuts/genres/rôles en `const … as const` + union type, **jamais `enum` TS**), `services/` (services API typés + `AuthService` signaux), `interceptors/` (`tokenInterceptor` Bearer+refresh 401 avec verrou `BehaviorSubject`, `errorInterceptor` → `ApiError`), `guards/` (`authGuard`, `adminGuard`, `guestGuard` fonctionnels), `utils/`.
- `layouts/admin/` : `admin-layout` (shell sidebar+topbar+drawer mobile), `sidebar`, `topbar`, `nav-icon`.
- `features/` : `auth/login`, `dashboard`, `products` (list + form + `products.routes.ts`), `categories`, `orders` (list + detail + `orders.routes.ts`), `customers`. Routes lazy via `loadComponent`/`loadChildren`.
- `shared/ui/` : kit complet — `button`, `inputs/` (text/textarea/number/select/checkbox), `card`, `badge`, `modal`+`confirm-dialog`, `feedback/` (spinner/empty-state/error-state/toast-container), `layout/` (page-header/pagination/language-switcher).

## Conventions clés
- **Données async** : `rxResource({ params: () => sig(), stream: ({params}) => service.obs(params) })` (de `@angular/core/rxjs-interop`). États : `resource.isLoading()`, `resource.status() === 'error'`, `resource.value()`, `resource.reload()`. Si `params` renvoie `undefined`, le loader ne tourne pas (utile en mode création).
- **Signal Forms** (`@angular/forms/signals`) : dispo et utilisé pour le login. Le **directive à importer dans `imports:[]` = `FormField`** (PAS `Field`, qui est un type). Sélecteur template `[formField]="form.champ"`. Validators : `required`, `email`, `minLength`, `pattern`… dans `form(model, (p) => {…})`. `submit(form, async () => …)` attend un retour `Promise<TreeValidationResult>` (renvoyer `undefined` = OK).
- **Kit inputs = `FormValueControl<T>`** : exposent `value = model<T>()` + inputs `errors`/`touched`. Double usage : `[formField]` (Signal Forms) OU `[value]` + `(valueChange)` (state signal maison, pour formulaires à tableaux dynamiques comme le form produit). Ne PAS nommer un input `min`/`max`/`pattern` sur un control (collision avec le contrat `FormUiControl`) → préférer `minValue`.
- **i18n maison** : `I18nService` (signal `locale`, `t(key, params)`), pipes **impures** `translate`/`money`/`localizedDate`. Dictionnaires `core/services/i18n/locales/{fr,en}.ts`, **parité testée** par `i18n-parity.spec.ts`. `fr` est la source (`as const` → `TranslationKey`), `en` typé `TranslationDictionary`. **Aucun texte UI en dur** : tout en clés. Argent FCFA via `formatMoney` (entiers, « 1 500 FCFA »).
- **Pas de déclaration inline** dans les `*.component.ts` : types/modèles de formulaire dans un `*.model.ts` à côté de la feature, mapping dans `*.util.ts`, constantes/unions dans `core/constants`.
- API base : `environment.apiUrl = 'http://localhost:8080/api'` ; endpoints centralisés dans `core/constants/api-endpoints.constants.ts`. Erreurs serveur attendues au format `{ code, messageKey, params, status }`.

## À câbler plus tard
- Upload d'images réel (le `ProductService.uploadImage` existe mais le form produit saisit des URLs ; brancher `POST /admin/uploads` + input file si besoin).
- Specs unitaires des composants/services (seuls app-shell + parité i18n couverts).
