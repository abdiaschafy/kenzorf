#!/usr/bin/env bash
# PostToolUse / Write|Edit — formate (best-effort) le fichier qui vient d'être écrit.
# Ne bloque ni n'échoue jamais le tool (toujours exit 0). Best-effort silencieux.
#
#  • Front Angular  (.ts .html .scss .css .json)  -> prettier local
#  • API .NET       (.cs)                          -> csharpier si installé
#                                                     (sinon skip : dotnet format est trop lent par édition ;
#                                                      activer avec :  dotnet tool install csharpier  dans le projet API)

input=$(cat)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
[ -z "$fp" ] && exit 0
[ -f "$fp" ] || exit 0

FRONT="/Users/abdiaschafanglontchi/kenzorf/back-office"
API="/Users/abdiaschafanglontchi/kenzorf/api"

case "$fp" in
  "$FRONT"/*)
    case "$fp" in
      *.ts|*.html|*.scss|*.css|*.json)
        PRETTIER="$FRONT/node_modules/.bin/prettier"
        [ -x "$PRETTIER" ] && "$PRETTIER" --write --log-level silent "$fp" >/dev/null 2>&1
        ;;
    esac
    ;;
  "$API"/*.cs)
    if command -v csharpier >/dev/null 2>&1; then
      csharpier format "$fp" >/dev/null 2>&1 || csharpier "$fp" >/dev/null 2>&1
    elif ( cd "$API" && dotnet csharpier --version ) >/dev/null 2>&1; then
      ( cd "$API" && dotnet csharpier format "$fp" >/dev/null 2>&1 || dotnet csharpier "$fp" >/dev/null 2>&1 )
    fi
    ;;
esac

exit 0
