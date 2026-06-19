---
description: Pipeline produit complet KENZORF (pm-po → architecte → devs → tests → review → boucle) avec validations humaines
argument-hint: <description du besoin / de la feature>
---

Tu orchestres le **pipeline produit complet** de KENZORF pour le besoin suivant :

> $ARGUMENTS

Respecte STRICTEMENT cet enchaînement, en t'arrêtant à chaque 🚦 **POINT DE VALIDATION** pour attendre mon accord avant de continuer. Ne saute jamais une étape. Ne committe jamais (feedback fondateur : livraison dans le working tree uniquement).

## Étape 1 — Cadrage produit (agent `pm-po`)
Lance l'agent **pm-po**. Il doit :
- revenir au problème utilisateur, challenger toute solution prématurée ;
- me poser les questions de cadrage manquantes (RBAC, tenant scoping, règles métier, périmètre MVP) ;
- rédiger les documents dev-ready dans `.claude/specs/` (PRD / user stories / critères d'acceptation / découpage).

🚦 **POINT DE VALIDATION 1** : présente-moi la synthèse du cadrage et les specs produites. **Attends mon accord** (« je me mets d'accord avec le PM ») avant l'étape 2. Intègre mes retours en rebouclant sur pm-po si besoin.

## Étape 2 — Cadrage technique (agent `fullstack-architect`)
Lance l'agent **fullstack-architect** sur les specs validées. Il doit cadrer les tâches des devs : où créer les fichiers, quelles interfaces/abstractions, quels patterns, quelles couches (Clean Archi back / Angular front / Flutter mobile), risques multi-tenant & RBAC, et une **checklist de mise en œuvre par agent dev**. Il ne code pas.

🚦 **POINT DE VALIDATION 2** : présente-moi le plan d'architecture et le découpage des tâches dev. **Attends mon accord** avant l'étape 3.

## Étape 3 — Implémentation (agents devs)
Détermine le périmètre touché et lance les agents dev concernés, **en parallèle quand les tâches sont indépendantes** :
- **dotnet-feature** pour l'API .NET 9 (endpoints, DTOs, validators, EF — migrations via `dotnet ef migrations add`, jamais à la main) ;
- **angular-feature** pour le front Angular 21 ;
- **flutter-feature** pour l'app mobile, si concernée.
Chaque dev suit la checklist de l'architecte.

## Étape 4 — Tests (agent `test-runner`)
Lance l'agent **test-runner** sur le périmètre modifié (back .NET + front Angular). Remonte uniquement les échecs et prérequis manquants.

## Étape 5 — Revue (agent `code-reviewer`)
Lance l'agent **code-reviewer** sur le diff : qualité, sécurité, multi-tenant, RBAC, paiements, auth, risques de régression.

## Étape 6 — Boucle
Si test-runner OU code-reviewer remontent des problèmes : **reboucle sur l'étape 3** (devs) en leur donnant précisément les correctifs, puis re-tests + re-review. Répète jusqu'à ce que tout soit vert.

🚦 **POINT DE VALIDATION FINAL** : présente-moi le bilan (specs, ce qui a été implémenté, tests verts, findings review résolus, ce qui reste). **Attends ma validation finale**. Ne committe pas — laisse tout dans le working tree.

Commence maintenant par l'étape 1.
