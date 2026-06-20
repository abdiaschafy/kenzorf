#!/usr/bin/env bash
# ------------------------------------------------------------------
#  Libère les ports passés en argument (défaut : 8080 4200 5432) :
#   1) stoppe les conteneurs Docker qui les publient (ex. un autre projet)
#   2) tue les process hôte (non-Docker) encore en écoute dessus
#  Sûr : ne touche jamais au proxy Docker ; tout échec est ignoré.
#  Usage : scripts/free-ports.sh [port ...]
# ------------------------------------------------------------------
set -uo pipefail

PORTS="${*:-8080 4200 5432}"
freed=0

for p in $PORTS; do
  # 1) Conteneurs Docker publiant ce port hôte
  if command -v docker >/dev/null 2>&1; then
    for cid in $(docker ps -q --filter "publish=$p" 2>/dev/null); do
      name=$(docker inspect -f '{{.Name}}' "$cid" 2>/dev/null | sed 's#^/##')
      echo "  ⏹  port $p : docker stop '$name'"
      docker stop "$cid" >/dev/null 2>&1 || true
      freed=1
    done
  fi

  # 2) Process hôte (hors Docker) encore en LISTEN sur ce port
  for pid in $(lsof -nP -iTCP:"$p" -sTCP:LISTEN -t 2>/dev/null); do
    cmd=$(ps -p "$pid" -o comm= 2>/dev/null || true)
    case "$cmd" in
      *docker*|*vpnkit*|*com.docke*|"" ) : ;;     # ne pas toucher au proxy Docker
      * )
        echo "  ⏹  port $p : kill $pid ($cmd)"
        kill "$pid" 2>/dev/null || true
        freed=1
        ;;
    esac
  done
done

if [ "$freed" = "1" ]; then
  echo "✅ Ports libérés : $PORTS"
else
  echo "✅ Ports déjà libres : $PORTS"
fi
