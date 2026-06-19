---
description: Contrôle pré-livraison KENZORF — tests + revue qualité/sécurité du diff courant, sans committer
argument-hint: (optionnel) périmètre ou contexte du lot à livrer
---

Fais le **contrôle pré-livraison** du travail en cours $ARGUMENTS. Objectif : me dire si le lot est **prêt à merger** (je gère le merge moi-même, ne committe rien).

1. **État du diff** — lance `git status --short` et `git diff --stat` pour cadrer ce qui a changé.
2. **Tests** (`test-runner`) — back .NET + front Angular sur le périmètre touché. Remonte uniquement échecs / prérequis manquants / le compte de tests verts.
3. **Revue** (`code-reviewer`) — qualité, sécurité, **multi-tenant (fail-closed)**, RBAC, paiements, auth, régressions. Donne des correctifs ciblés.
4. **Bilan de livraison** structuré :
   - ✅ ce qui est prêt ;
   - ⚠️ findings bloquants à corriger avant merge (avec fichier:ligne) ;
   - 📋 findings non bloquants / dette assumée ;
   - 🧪 statut des tests (nombre vert / échecs).
5. Termine par un verdict clair : **« prêt à merger »** ou **« à corriger »** avec la liste d'actions.

Pour une revue plus poussée en parallèle, propose-moi `/workflows` → `revue-qualite`. Ne committe pas, ne crée pas de branche ni de PR.
