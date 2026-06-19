---
description: Lance le workflow multi-agent de revue qualité/sécurité du diff courant (bugs, sécu, multi-tenant, RBAC, paiements, perf)
---

Lance le **workflow** `revue-qualite` (via le tool Workflow) sur le diff courant de KENZORF.

Ce workflow review le diff en parallèle sur 6 dimensions (avec l'agent `code-reviewer`), **réfute adversarialement** chaque finding pour éliminer les faux positifs, puis synthétise.

À la fin, présente-moi :
- le **verdict** global (✅ prêt à merger / ⚠️ à corriger) ;
- les **blockers** avec `fichier:ligne` ;
- les **non-bloquants** / dette assumée ;
- le nombre de findings confirmés après vérification.

Ne committe rien — c'est une revue, je gère le merge moi-même.
