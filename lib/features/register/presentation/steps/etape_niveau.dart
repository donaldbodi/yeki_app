import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

/// Étape 4/5 (apprenant uniquement) — choix du niveau, dépendant du
/// département choisi à l'étape précédente. Consomme
/// `FormationRepository.niveauxForDepartement` (fonction canonique
/// unique — voir docs/ecarts/register.md), jamais une liste en dur.
class EtapeNiveau extends StatelessWidget {
  const EtapeNiveau({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final ValueListenable<List<String>?> options;
  final ValueListenable<String?> selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Votre niveau', style: YkTypography.h2(context)),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Selon le département choisi.',
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.md),
          ValueListenableBuilder<List<String>?>(
            valueListenable: options,
            builder: (context, opts, _) {
              return ValueListenableBuilder<String?>(
                valueListenable: selected,
                builder: (context, sel, _) => YkDropdown<String>(
                  label: 'Niveau',
                  isLoading: opts == null,
                  emptyMessage: 'Aucun niveau disponible',
                  value: sel,
                  items: [
                    for (final n in opts ?? const <String>[]) YkDropdownItem(value: n, label: n),
                  ],
                  onChanged: onSelected,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
