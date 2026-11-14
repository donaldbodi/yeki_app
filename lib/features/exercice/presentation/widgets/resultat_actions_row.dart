import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

/// Actions de bas de page — « Toutes les tentatives » toujours visible,
/// « Refaire l'exercice » masqué si [tentativesEpuisees] (corrige le
/// bug de l'ancien `_refaireExercice`, qui restait actif même à sec —
/// voir docs/ecarts/resultat_exercice.md).
class ResultatActionsRow extends StatelessWidget {
  const ResultatActionsRow({
    super.key,
    required this.tentativesEpuisees,
    required this.onVoirTentatives,
    required this.onRefaire,
  });

  final bool tentativesEpuisees;
  final VoidCallback onVoirTentatives;
  final VoidCallback onRefaire;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: YkButton(
            label: 'Toutes les tentatives',
            icon: Icons.history_rounded,
            variant: YkButtonVariant.secondary,
            onPressed: onVoirTentatives,
          ),
        ),
        if (!tentativesEpuisees) ...[
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: YkButton(label: "Refaire l'exercice", icon: Icons.refresh_rounded, onPressed: onRefaire),
          ),
        ],
      ],
    );
  }
}
