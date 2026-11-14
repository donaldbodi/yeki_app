#!/usr/bin/env bash
# tool/check_design_system.sh
#
# Pare-feu du design system YÉKI (P4.2) — CDC_DESIGN §9.
# Mécanisme de cliquet : échoue si un chiffre augmente par rapport à
# tool/baseline.txt, abaisse automatiquement la limite quand il diminue.
# Permet une migration progressive tout en rendant la régression impossible.
#
# Usage :
#   bash tool/check_design_system.sh          # règles 1-8 (rapide, pre-commit)
#   bash tool/check_design_system.sh --full    # + règle 9 flutter analyze (CI)
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

BASELINE_FILE="tool/baseline.txt"
FULL=0
if [[ "${1:-}" == "--full" || "${CHECK_DESIGN_FULL:-0}" == "1" ]]; then
  FULL=1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAIL=0
declare -A CURRENT

# Compte les lignes d'une sortie (0 si vide) et affiche nom + 10 premières.
report_rule() {
  local key="$1" name="$2" output="$3"
  local count=0
  if [[ -n "$output" ]]; then
    count=$(printf '%s\n' "$output" | wc -l | tr -d ' ')
  fi
  CURRENT["$key"]=$count
  echo ""
  echo "== $name =="
  echo "Occurrences : $count"
  if [[ $count -gt 0 ]]; then
    printf '%s\n' "$output" | head -10
  fi
}

echo "Vérification du design system YÉKI (P4.2)"
echo "=========================================="

OUT1=$(grep -rn "Color(0x" lib/ --include="*.dart" 2>/dev/null | grep -v "lib/core/design/tokens/" || true)
report_rule couleurs_dur "Règle 1 — Couleurs en dur hors tokens/" "$OUT1"

OUT2=$(grep -rn "BoxDecoration(" lib/ --include="*.dart" 2>/dev/null | grep -v "lib/core/design/" || true)
report_rule boxdecoration_dur "Règle 2 — BoxDecoration hors design/" "$OUT2"

OUT3=$(grep -rn "TextStyle(" lib/ --include="*.dart" 2>/dev/null | grep -v "lib/core/design/" || true)
report_rule textstyle_dur "Règle 3 — TextStyle hors design/" "$OUT3"

OUT4=$(grep -rn "import 'dart:io'" lib/ 2>/dev/null || true)
report_rule dart_io "Règle 4 — import dart:io" "$OUT4"

OUT5=$(grep -rn "http\.\(get\|post\|put\|patch\|delete\)" lib/ 2>/dev/null || true)
report_rule http_direct "Règle 5 — appels http directs" "$OUT5"

OUT6=$(grep -rn "Navigator\.push\|Navigator\.of(context)\.push" lib/ 2>/dev/null || true)
report_rule navigator_push "Règle 6 — Navigator.push impératif" "$OUT6"

OUT7=$(grep -rn "setState(" lib/features/ 2>/dev/null || true)
report_rule setstate_features "Règle 7 — setState dans lib/features/" "$OUT7"

OUT8=$(grep -rn "app_theme.dart\|yeki_design_system.dart\|yeki_design.dart\|yeki_design_extension.dart" lib/ 2>/dev/null || true)
report_rule imports_anciens_themes "Règle 8 — imports des anciens fichiers de thème" "$OUT8"

ORDER=(couleurs_dur boxdecoration_dur textstyle_dur dart_io http_direct navigator_push setstate_features imports_anciens_themes)

if [[ $FULL -eq 1 ]]; then
  echo ""
  echo "== Règle 9 — flutter analyze =="
  ANALYZE_OUTPUT=$(flutter analyze 2>&1 || true)
  ERROR_COUNT=$(printf '%s\n' "$ANALYZE_OUTPUT" | grep -Ec '^[[:space:]]*error -' || true)
  WARNING_COUNT=$(printf '%s\n' "$ANALYZE_OUTPUT" | grep -Ec '^[[:space:]]*warning -' || true)
  INFO_COUNT=$(printf '%s\n' "$ANALYZE_OUTPUT" | grep -Ec '^[[:space:]]*info -' || true)
  echo "Erreurs : $ERROR_COUNT (porte stricte, doit toujours être 0, jamais négociable)"
  echo "Warnings : $WARNING_COUNT (cliquet — voir tool/baseline.txt)"
  echo "Infos (dont dépréciations design system en cours de migration) : $INFO_COUNT"
  if [[ $ERROR_COUNT -gt 0 ]]; then
    echo -e "${RED}Erreurs détectées (jamais tolérées, indépendamment de la baseline) :${NC}"
    printf '%s\n' "$ANALYZE_OUTPUT" | grep -E '^[[:space:]]*error -' | head -10
    FAIL=1
  fi
  CURRENT["analyze_warning"]=$WARNING_COUNT
  CURRENT["analyze_info"]=$INFO_COUNT
  ORDER+=(analyze_warning analyze_info)
fi

echo ""
echo "== Comparaison à la baseline =="

if [[ ! -f "$BASELINE_FILE" ]]; then
  echo "Aucune baseline trouvée — initialisation de $BASELINE_FILE"
  {
    for k in "${ORDER[@]}"; do
      echo "$k=${CURRENT[$k]}"
    done
  } > "$BASELINE_FILE"
  echo "Baseline initialisée avec les valeurs actuelles. Pensez à : git add $BASELINE_FILE"
  exit 0
fi

declare -A BASELINE
while IFS='=' read -r k v; do
  [[ -z "$k" || "$k" == \#* ]] && continue
  BASELINE["$k"]=$v
done < "$BASELINE_FILE"

UPDATED=0
declare -A NEW_BASELINE
for k in "${ORDER[@]}"; do
  cur=${CURRENT[$k]}
  if [[ -z "${BASELINE[$k]+x}" ]]; then
    # Nouvelle métrique jamais mesurée : on adopte la valeur actuelle,
    # rien à comparer.
    echo -e "${YELLOW}Nouvelle métrique [$k] : baseline initialisée à $cur${NC}"
    NEW_BASELINE["$k"]=$cur
    UPDATED=1
    continue
  fi
  base=${BASELINE[$k]}
  if [[ $cur -gt $base ]]; then
    echo -e "${RED}RÉGRESSION [$k] : $cur > baseline $base${NC}"
    FAIL=1
    NEW_BASELINE["$k"]=$base
  elif [[ $cur -lt $base ]]; then
    echo -e "${YELLOW}Amélioration [$k] : baseline abaissée $base → $cur${NC}"
    NEW_BASELINE["$k"]=$cur
    UPDATED=1
  else
    NEW_BASELINE["$k"]=$base
  fi
done

# Conserve toute clé de l'ancienne baseline non mesurée dans cette exécution
# (ex. analyze_info, absent en mode rapide pre-commit).
for k in "${!BASELINE[@]}"; do
  if [[ -z "${NEW_BASELINE[$k]+x}" ]]; then
    NEW_BASELINE["$k"]=${BASELINE[$k]}
  fi
done

if [[ $UPDATED -eq 1 ]]; then
  {
    for k in "${!NEW_BASELINE[@]}"; do
      echo "$k=${NEW_BASELINE[$k]}"
    done
  } | sort > "$BASELINE_FILE"
  echo "baseline.txt mis à jour automatiquement. Pensez à : git add $BASELINE_FILE"
fi

echo ""
if [[ $FAIL -eq 1 ]]; then
  echo -e "${RED}ÉCHEC — au moins une régression détectée.${NC}"
  exit 1
else
  echo -e "${GREEN}OK — aucune régression.${NC}"
  exit 0
fi
