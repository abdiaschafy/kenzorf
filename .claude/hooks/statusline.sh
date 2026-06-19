#!/usr/bin/env bash
# Statusline Djara Connect — affiche projet · branche git (+ fichiers modifiés) · dossier courant · modèle.
# Reçoit en stdin le JSON de session de Claude Code.

input=$(cat)
model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
cdir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // "."')
[ -d "$cdir" ] || cdir="."
base=$(basename "$cdir")

branch=$(git -C "$cdir" rev-parse --abbrev-ref HEAD 2>/dev/null)
dirty=$(git -C "$cdir" status --porcelain 2>/dev/null | grep -c .)

# Sous-périmètre (back / front / mobile) selon le dossier courant
zone="djara-connect"
case "$cdir" in
  *djara-connect-api-dotnet*) zone="api .NET" ;;
  *djara-connect-front*)      zone="front Angular" ;;
  *flutter*|*mobile*)         zone="mobile Flutter" ;;
esac

# Couleurs ANSI
r=$'\033[0m'; cyan=$'\033[36m'; yel=$'\033[33m'; dim=$'\033[2m'; grn=$'\033[32m'; mag=$'\033[35m'

out="${mag}🚌 ${zone}${r}"
[ -n "$branch" ] && out="${out}  ${cyan}⎇ ${branch}${r}"
[ "${dirty:-0}" != "0" ] && out="${out} ${yel}✱${dirty}${r}"
out="${out}  ${dim}▸ ${base}${r}  ${dim}·${r}  ${grn}${model}${r}"

printf '%s' "$out"
