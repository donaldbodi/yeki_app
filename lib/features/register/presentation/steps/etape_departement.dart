import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/formation_repository.dart';

/// Étape 3/5 (apprenant uniquement) — choix du département, dépendant du
/// parcours choisi à l'étape précédente.
class EtapeDepartement extends StatelessWidget {
  const EtapeDepartement({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final ValueListenable<List<DepartementOption>?> options;
  final ValueListenable<DepartementOption?> selected;
  final ValueChanged<DepartementOption?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Votre département', style: YkTypography.h2(context)),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Selon le parcours choisi.',
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.md),
          ValueListenableBuilder<List<DepartementOption>?>(
            valueListenable: options,
            builder: (context, opts, _) {
              return ValueListenableBuilder<DepartementOption?>(
                valueListenable: selected,
                builder: (context, sel, _) => YkDropdown<int>(
                  label: 'Département',
                  isLoading: opts == null,
                  emptyMessage: 'Aucun département disponible',
                  value: sel?.id,
                  items: [
                    for (final d in opts ?? const <DepartementOption>[])
                      YkDropdownItem(value: d.id, label: d.nom),
                  ],
                  onChanged: (id) {
                    final match = (opts ?? const <DepartementOption>[])
                        .where((d) => d.id == id)
                        .cast<DepartementOption?>()
                        .firstOrNull;
                    onSelected(match);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
