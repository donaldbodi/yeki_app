import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/formation_repository.dart';

/// Étape 2/5 (apprenant uniquement) — choix du parcours, chargé depuis
/// l'API (JAMAIS en dur — exigence explicite du ticket).
class EtapeParcours extends StatelessWidget {
  const EtapeParcours({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final ValueListenable<List<ParcoursOption>?> options;
  final ValueListenable<ParcoursOption?> selected;
  final ValueChanged<ParcoursOption?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Votre parcours', style: YkTypography.h2(context)),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Choisissez le parcours qui correspond à votre projet.',
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.md),
          ValueListenableBuilder<List<ParcoursOption>?>(
            valueListenable: options,
            builder: (context, opts, _) {
              return ValueListenableBuilder<ParcoursOption?>(
                valueListenable: selected,
                builder: (context, sel, _) => YkDropdown<int>(
                  label: 'Parcours',
                  isLoading: opts == null,
                  emptyMessage: 'Aucun parcours disponible',
                  value: sel?.id,
                  items: [
                    for (final p in opts ?? const <ParcoursOption>[])
                      YkDropdownItem(value: p.id, label: p.nom),
                  ],
                  onChanged: (id) {
                    final match = (opts ?? const <ParcoursOption>[])
                        .where((p) => p.id == id)
                        .cast<ParcoursOption?>()
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
