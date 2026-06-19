---
description: Cadrage produit KENZORF via l'agent pm-po (problème → specs dev-ready dans .claude/specs/)
argument-hint: <besoin / idée / problème à cadrer>
---

Lance l'agent **pm-po** pour cadrer le besoin suivant :

> $ARGUMENTS

L'agent doit :
- remonter au **problème utilisateur** et challenger toute solution amenée trop tôt ;
- me poser les **questions de cadrage** manquantes avant d'écrire quoi que ce soit (RBAC, tenant scoping, règles métier RG-*, périmètre MVP, parcours) ;
- produire les documents **dev-ready** dans `.claude/specs/` : PRD ou note de cadrage, user stories avec critères d'acceptation testables, découpage en lots, priorisation explicite et handoff dev.

À la fin, présente-moi la **synthèse** et la liste des fichiers de specs créés, puis demande si on enchaîne avec l'architecte (`/feature` reprend le pipeline complet) ou si j'ai des ajustements.

Ne code pas, ne modifie pas le code source — uniquement des documents produit.
