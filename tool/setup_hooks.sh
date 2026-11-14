#!/usr/bin/env bash
# tool/setup_hooks.sh
#
# À lancer une fois après le clonage du dépôt : active les hooks git
# versionnés dans tool/githooks/ (dont le pare-feu design system, P4.2).
set -euo pipefail

git config core.hooksPath tool/githooks
echo "Hooks git activés (core.hooksPath=tool/githooks)."
