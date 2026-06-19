#!/usr/bin/env bash
# PreToolUse / Write — empêche la CRÉATION manuelle d'un fichier de migration EF Core.
#
# Feedback "ef_migrations_never_handwrite" : une migration écrite à la main n'a pas de
# [Migration]/Designer, ne s'applique pas (500 "column does not exist") et reste invisible aux tests.
# Toujours générer via `dotnet ef migrations add`.
#
# Note : on bloque Write (création / écrasement). L'édition (Edit) d'une migration déjà GÉNÉRÉE
# reste possible pour ajuster du SQL custom.

input=$(cat)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
[ -z "$fp" ] && exit 0

case "$fp" in
  */Migrations/*.cs)
    reason="🚫 Garde-fou KENZORF — création manuelle d'une migration EF interdite : « $fp ». Génère-la plutôt avec : dotnet ef migrations add <Nom> --project src/KENZORF.Infrastructure --startup-project src/KENZORF.Api. Une migration écrite à la main n'a ni Designer ni attribut [Migration] : elle ne s'applique pas et est invisible aux tests. (Pour ajuster une migration DÉJÀ générée, utilise Edit, pas Write.)"
    jq -nc --arg r "$reason" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
    ;;
esac

exit 0
