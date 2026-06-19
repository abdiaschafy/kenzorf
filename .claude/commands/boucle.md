---
description: Déroule la boucle technique KENZORF sur une spec déjà cadrée (architecte → devs → tests → review → reboucle)
argument-hint: <nom de la spec dans .claude/specs/ ou périmètre à implémenter>
---

Le cadrage produit est **déjà fait**. Déroule la **boucle technique** sur :

> $ARGUMENTS

Si l'argument désigne une spec, lis-la d'abord dans `.claude/specs/`. Si plusieurs specs correspondent, demande-moi laquelle.

1. **Architecte** (`fullstack-architect`) — *uniquement si le cadrage technique n'a pas encore été fait pour ce lot* : où placer les fichiers, interfaces, patterns, risques multi-tenant/RBAC, checklist par dev. Sinon passe directement à l'étape 2.
2. **Devs** — lance les agents concernés (**dotnet-feature**, **angular-feature**, **flutter-feature**) **en parallèle quand c'est indépendant**. Migrations EF via `dotnet ef migrations add`, jamais à la main.
3. **Tests** (`test-runner`) sur le périmètre modifié.
4. **Review** (`code-reviewer`) sur le diff.
5. **Reboucle** sur l'étape 2 tant que test-runner ou code-reviewer remontent des problèmes, en passant aux devs les correctifs précis.

À la fin, présente le bilan (implémenté / tests / findings résolus / reste à faire) et **attends ma validation**. Ne committe pas — laisse tout dans le working tree.
