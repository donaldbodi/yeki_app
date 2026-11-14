import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/exercice_models.dart';

const _typeOptions = [
  YkDropdownItem(value: 'all', label: 'Tous les types'),
  YkDropdownItem(value: 'general', label: 'Généraux'),
  YkDropdownItem(value: 'module', label: 'Par module'),
  YkDropdownItem(value: 'lecon', label: 'Par leçon'),
  YkDropdownItem(value: 'epreuve', label: 'Épreuves'),
];

const _etoileLabels = ['Tous', 'Très facile', 'Facile', 'Moyen', 'Difficile', 'Expert'];

/// Filtres de l'onglet « Exercices » — type, module, leçon, difficulté,
/// recherche texte. Purement présentationnel (valeurs + callbacks), état
/// porté par `ExercicesCoursController` (règle 7 : pas de `setState`).
class FiltresRow extends StatelessWidget {
  const FiltresRow({
    super.key,
    required this.typeFiltre,
    required this.onTypeChanged,
    required this.modules,
    required this.moduleFiltre,
    required this.onModuleChanged,
    required this.leconFiltre,
    required this.onLeconChanged,
    required this.etoileFiltre,
    required this.onEtoileChanged,
    required this.onRechercheChanged,
  });

  final String typeFiltre;
  final ValueChanged<String?> onTypeChanged;
  final List<ModuleOption> modules;
  final int? moduleFiltre;
  final ValueChanged<int?> onModuleChanged;
  final int? leconFiltre;
  final ValueChanged<int?> onLeconChanged;
  final int etoileFiltre;
  final ValueChanged<int> onEtoileChanged;
  final ValueChanged<String> onRechercheChanged;

  @override
  Widget build(BuildContext context) {
    ModuleOption? moduleSelectionne;
    if (moduleFiltre != null) {
      for (final m in modules) {
        if (m.id == moduleFiltre) {
          moduleSelectionne = m;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: YkDropdown<String>(
                label: 'Type',
                value: typeFiltre,
                items: _typeOptions,
                onChanged: onTypeChanged,
              ),
            ),
            if (modules.isNotEmpty) ...[
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: YkDropdown<int?>(
                  label: 'Module',
                  value: moduleFiltre,
                  items: [
                    const YkDropdownItem(value: null, label: 'Tous'),
                    for (final m in modules) YkDropdownItem(value: m.id, label: m.titre),
                  ],
                  onChanged: onModuleChanged,
                ),
              ),
            ],
          ],
        ),
        if (moduleSelectionne != null && moduleSelectionne.lecons.isNotEmpty) ...[
          SizedBox(height: YkSpacing.sm),
          YkDropdown<int?>(
            label: 'Leçon',
            value: leconFiltre,
            items: [
              const YkDropdownItem(value: null, label: 'Toutes les leçons'),
              for (final l in moduleSelectionne.lecons) YkDropdownItem(value: l.id, label: l.titre),
            ],
            onChanged: onLeconChanged,
          ),
        ],
        SizedBox(height: YkSpacing.sm),
        YkTextField(
          type: YkTextFieldType.search,
          hint: 'Rechercher un exercice…',
          onChanged: onRechercheChanged,
        ),
        SizedBox(height: YkSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _etoileLabels.length,
            separatorBuilder: (_, _) => SizedBox(width: YkSpacing.xs),
            itemBuilder: (context, index) => YkChip(
              label: _etoileLabels[index],
              variant: YkChipVariant.filter,
              selected: etoileFiltre == index,
              onSelected: (_) => onEtoileChanged(index),
            ),
          ),
        ),
      ],
    );
  }
}
