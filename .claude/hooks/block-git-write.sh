#!/usr/bin/env bash
# PreToolUse / Bash — empêche Claude d'exécuter des commandes git/gh qui ÉCRIVENT
# (commit, push, add, branche, merge, reset, PR…).
#
# Feedback fondateur "never_commit" : Claude livre dans le working tree et s'arrête ;
# le fondateur gère git lui-même.
#
# Échappatoire conscient : lancer Claude avec  DJARA_ALLOW_GIT=1  pour autoriser ces commandes.
#
# Lecture git (status, diff, log, show…) reste autorisée.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Échappatoire explicite
[ "${DJARA_ALLOW_GIT:-0}" = "1" ] && exit 0
[ -z "$cmd" ] && exit 0

# Normalise les espaces/tabs pour fiabiliser les regex
norm=$(printf '%s' "$cmd" | tr '\t' ' ' | tr -s ' ')

deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Verbes git destructifs / d'écriture (n'importe où dans une commande chaînée)
if printf '%s' "$norm" | grep -Eiq '\bgit +(commit|push|add|am|cherry-pick|merge|rebase|reset|revert|tag|stash|pull|clean|rm|mv|filter-branch|update-ref)\b' \
   || printf '%s' "$norm" | grep -Eiq '\bgit +(switch +-c|checkout +-b|branch +[^ -])' \
   || printf '%s' "$norm" | grep -Eiq '\bgh +(pr|release) +(create|merge|edit|close)\b'; then
  deny "🚫 Garde-fou KENZORF — commande git/gh d'écriture bloquée : « $cmd ». Feedback fondateur « never_commit » : livre dans le working tree et arrête-toi, le fondateur gère git lui-même (commit / add / push / branche / PR). Contournement conscient : relancer Claude avec DJARA_ALLOW_GIT=1."
fi

exit 0
