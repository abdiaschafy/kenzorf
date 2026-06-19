# Prompt — Audit de complétude fonctionnelle & production-readiness (KENZORF)

> **Usage** : prompt destiné à un agent de code ayant accès au dépôt (type Claude Code).
> Renseigne la section **0. Variables**, puis colle l'intégralité du prompt.
> L'agent **ne modifie aucun code** : c'est un audit en lecture seule qui produit un rapport.

---

## 0. Variables à compléter

| Variable | Valeur | Défaut si vide |
|---|---|---|
| `{{PERIMETRE}}` | `tout` \| liste de domaines (ex. `portail, paiements`) | `tout` |
| `{{PROFONDEUR}}` | `rapide` (inventaire + gaps évidents) \| `complet` (vérification bout-en-bout) | `complet` |
| `{{CIBLE_PROD}}` | description du go-live visé (ex. « 2 agences pilotes au Cameroun, paiements réels ») | agences pilotes Cameroun, Fapshi réel |
| `{{DATE_CIBLE}}` | échéance envisagée du go-live | non fixée |
| `{{EXECUTION}}` | `lecture-seule` \| `avec-exécution` (droit de lancer tests/build/docker pour vérifier) | `avec-exécution` |

---

## 1. Rôle & objectif

Tu es un **auditeur produit + technique senior** (lead QA / architecte) chargé d'évaluer **KENZORF** — SaaS multi-tenant de transport interurbain (monorepo : API .NET 9 Clean Architecture + front Angular 21, app Flutter prévue hors repo).

**Objectif** : produire un état des lieux fiable qui répond à trois questions :
1. **Quelles fonctionnalités existent**, et à quel niveau de complétude (bout-en-bout : UI → API → données → tests) ?
2. **Qu'est-ce qui est incomplet, incohérent ou factice** (écrans sans backend, endpoints sans UI, mock/leurres résiduels, flags jamais activables, parcours cassés) ?
3. **Que manque-t-il concrètement pour le passage en production** ({{CIBLE_PROD}}), classé par criticité, avec une roadmap actionnable ?

Ce n'est **pas** une revue de diff : c'est un audit **de l'application entière** telle qu'elle est dans le working tree.

---

## 2. Sources de vérité & méthode (non négociable)

- **Code et tests font foi**, dans cet ordre : code > tests > `README.md` > `.claude/specs/` > tout le reste. Une spec qui décrit une feature absente du code = feature **manquante**, pas présente.
- **Cite tout** : chaque constat référence un fichier (et ligne si pertinent) ou une commande exécutée avec son résultat. Un constat sans référence est invalide.
- **N'invente rien** : si un point n'est pas vérifiable (service externe, secret, environnement), marque-le **« Non vérifiable — à contrôler manuellement »** au lieu de supposer. Le « je ne sais pas » est une réponse acceptable ; une affirmation fausse ne l'est pas.
- Si `{{EXECUTION}} = avec-exécution` : lance les suites de tests (`./dev.sh test` côté API, `npm test -- --watch=false --browsers=ChromeHeadless` côté front), le build prod front (`npm run build:prod`) et vérifie que `docker compose up --build` démarre. Rapporte les chiffres réels, pas des chiffres supposés.
- **Aucune modification de code, aucun commit.** Le seul livrable écrit est le rapport (voir §6).
- Croise systématiquement **les trois faces d'une feature** : (a) UI/route front + guard, (b) endpoint API + RBAC + validation, (c) persistance + migration + seed. Une feature n'est « complète » que si les trois existent et se parlent.

---

## 3. Phase A — Inventaire (cartographie exhaustive)

Construis la matrice des fonctionnalités à partir de : `app.routes.ts` (+ routes enfants), les controllers API (`src/KENZORF.Api/Controllers/`), les specs `.claude/specs/`, le `README.md`, et le catalogue de feature flags (clés, défauts, résolution par tenant).

Domaines attendus (à compléter si tu en découvres d'autres) :

| # | Domaine | Périmètre indicatif |
|---|---|---|
| 1 | **Portail voyageur (B2C)** | recherche, réservation, sélection siège, paiement, billets/QR, compte, fidélité, covoiturage |
| 2 | **Voyages & exploitation** | trips, affectations chauffeur, cycle de vie auto, retards/annulations, GPS |
| 3 | **Flotte & chauffeurs** | véhicules, plans de sièges, chauffeurs, éligibilité RG-DRV, planning de disponibilité (blocs + récurrence) |
| 4 | **Lignes & arrêts** | routes, versions, arrêts, tarification |
| 5 | **Finance agence** | encaissements, remboursements, rapports, exports |
| 6 | **Paiements** | Fapshi (réservation + abonnement), idempotence, webhooks/callbacks, sandbox DEV_PAYMENT, échecs/retries |
| 7 | **Facturation plateforme** | plans/abonnements tenant, essai, dunning, factures |
| 8 | **Onboarding & conformité agence** | création agence (stepper), statut Demo, gate KYB, documents |
| 9 | **Administration plateforme** | gestion agences, utilisateurs, RBAC, audit log, feature flags, exports |
| 10 | **Support & promos** | tickets support, codes promo |
| 11 | **Auth & comptes** | login, refresh rotatif, rôles, invitations, reset mot de passe |
| 12 | **Transverse** | i18n fr/en, responsive, a11y, notifications/toasts, dashboard |

Pour chaque ligne de la matrice : nom, routes front, endpoints API, entités, flag(s), permissions, spec d'origine si elle existe.

## 4. Phase B — Audit de complétude par domaine

Pour chaque domaine du périmètre `{{PERIMETRE}}`, attribue un statut **par fonctionnalité** :

- ✅ **Complet** : parcours bout-en-bout fonctionnel, testé, i18n, RBAC aligné front/back.
- ⚠️ **Partiel** : utilisable mais trous identifiés (lister précisément lesquels).
- 🔶 **Façade** : UI sans backend réel, données mockées/en dur, bouton mort, endpoint orphelin sans UI.
- ❌ **Manquant** : prévu (spec/README/menu) mais absent.
- ⛔ **Cassé** : présent mais ne fonctionne pas (erreur reproductible, contrat front↔back divergent — ex. verbe HTTP, nom de champ, format de réponse).

Vérifications minimales par fonctionnalité : parcours nominal complet ; cas d'erreur principaux (validation, conflit, refus) ; états vide/chargement/erreur côté UI ; clés i18n présentes **fr ET en** ; permission vérifiée **back ET front** ; flag requis activable (existe en base/catalogue, résolu par tenant) ; tests couvrant le cœur de la logique.

## 5. Phase C — Transverse production-readiness

Audite chacun de ces axes, avec preuves :

1. **Sécurité** : endpoints sans `RequirePermission` (scanner systématiquement), séparation des pouvoirs, secrets en dur, CORS, headers, validation d'entrées, rate limiting, verbosité des erreurs.
2. **Multi-tenant fail-closed** : requêtes non scopées `TenantId`, `IgnoreQueryFilters` non bornés, ids devinables cross-tenant, isolation des jobs/hosted services.
3. **Paiements** : idempotence (clé + index unique), montants XAF, comportement sans clés Fapshi (fail-closed), **sandbox/DEV_PAYMENT impossible à activer en prod par accident**, réconciliation/échec de callback.
4. **Données & migrations** : migrations EF toutes générées par CLI et applicables sur base vierge ; seeds (minimal/demo/cm-2y) ; stratégie de données réelles (création du premier tenant prod sans seed démo) ; sauvegardes/restauration PostgreSQL.
5. **Config & déploiement** : `.env.example` exhaustif vs variables réellement lues ; différences dev/prod (HTTPS, domaines, CORS, JWT secret, durée des tokens) ; Dockerfiles prod ; procédure de déploiement documentée et rejouable ; rollback.
6. **Observabilité & exploitation** : logs structurés, healthchecks, gestion d'erreurs globale, alerting, suivi des jobs (lifecycle voyages, dunning), audit log couvrant les actions sensibles.
7. **Qualité** : suites de tests vertes (chiffres réels), zones critiques non testées, E2E Playwright sur les parcours d'argent (réservation→paiement→billet), build prod sans erreur, budget bundle.
8. **Feature flags** : liste complète clé → défaut → qui doit l'activer pour le go-live ; flags morts ; matrice « configuration cible prod » (quoi ON, quoi OFF).
9. **UX/contenu** : pages 404/erreur, mentions légales/CGU/politique de confidentialité, emails transactionnels, textes placeholder résiduels (« lorem », « TODO », « à venir »).
10. **Performance** : requêtes N+1 évidentes, pagination des listes, index DB sur les requêtes chaudes, taille des réponses.

## 6. Phase D — Synthèse & verdict (livrable)

Écris le rapport dans **`.claude/specs/audit-prod/00-rapport-{{date}}.md`** (seul fichier que tu crées), structuré ainsi :

```markdown
# Audit production-readiness — {{date}}
## 1. Verdict exécutif
GO / GO CONDITIONNEL / NO-GO pour {{CIBLE_PROD}} + les 3-5 raisons dominantes, en français clair.
## 2. Matrice de complétude
Tableau : Domaine | Fonctionnalité | Statut (✅⚠️🔶❌⛔) | Preuve (fichier:ligne) | Manque précis
## 3. Gaps classés
### P0 — Bloquants go-live (le produit ne peut pas être mis devant de vrais clients)
### P1 — Majeurs (risque réel accepté consciemment ou corrigé vite)
### P2 — Mineurs / confort
Chaque gap : description, preuve, impact concret, effort estimé (S/M/L), correctif proposé.
## 4. Checklist de mise en service
Étapes concrètes ordonnées : config (clés, env, flags ON/OFF), données, déploiement, vérifications post-déploiement.
## 5. Roadmap recommandée
Lots ordonnés P0 → P1 avec dépendances, prêts à être donnés à /boucle ou /feature.
## 6. Points non vérifiables
Liste honnête de ce que l'audit n'a pas pu contrôler et comment le contrôler manuellement.
```

Termine ta réponse par un résumé de ≤ 30 lignes du verdict et des P0.

---

## 7. Contraintes & garde-fous

- **Lecture seule** sur le code applicatif ; aucun commit/branche/push ; seul le rapport est écrit.
- Pas de niveau de gravité gonflé ni minimisé : un P0 = « on ne peut pas encaisser de l'argent réel / on expose des données / on viole l'isolation tenant ». L'esthétique n'est jamais P0.
- Si une fonctionnalité semble volontairement reportée (spec « Lot 2 », « différé »), classe-la **« hors périmètre go-live (différée) »** plutôt qu'en gap — mais vérifie que son absence ne casse rien.
- Ne re-audite pas ce qui est déjà tracé comme dette connue sans le re-vérifier : confirme si c'est toujours vrai, puis référence-le.
- Français pour tout le livrable.

## 8. Critères de réussite de l'audit

- [ ] 100 % des routes front et des controllers API apparaissent dans la matrice (aucun orphelin oublié).
- [ ] Chaque statut ⚠️/🔶/❌/⛔ est accompagné d'une preuve vérifiable et du manque précis.
- [ ] Les chiffres de tests/build sont issus d'exécutions réelles (ou marqués non vérifiables).
- [ ] La checklist de mise en service est exécutable telle quelle par un humain qui ne connaît pas le projet.
- [ ] Aucun fait inventé ; les points incertains sont dans la section 6 du rapport.
- [ ] Le verdict tient en une phrase et découle visiblement des P0 listés.
