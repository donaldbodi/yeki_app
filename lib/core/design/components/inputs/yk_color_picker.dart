import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Sélecteur de couleur de cours — CDC_DESIGN §3.3/§5.3.2. **Règle
/// métier, pas décoration** : alimenté EXCLUSIVEMENT par
/// `YkCourseColors.palette` — pas de paramètre `palette`, volontairement
/// absent de l'API, pour qu'aucun appelant ne puisse jamais y substituer
/// une autre source. Ce composant ne doit être utilisé que dans les
/// formulaires de création/modification de cours (ou de département) —
/// toute autre page affichant un cours lit sa couleur depuis le champ
/// `couleur` renvoyé par l'API, jamais depuis cette palette.
class YkColorPicker extends StatelessWidget {
  const YkColorPicker({super.key, required this.selectedHex, required this.onChanged, this.label});

  /// Couleur actuellement choisie, au format `#RRGGBB` (ou `null`).
  final String? selectedHex;
  final ValueChanged<String> onChanged;
  final String? label;

  static String hexOf(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final selected = selectedHex?.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(height: YkSpacing.xs),
        ],
        Wrap(
          spacing: YkSpacing.sm,
          runSpacing: YkSpacing.sm,
          children: [
            for (final swatch in YkCourseColors.palette)
              _Swatch(
                swatch: swatch,
                selected: hexOf(swatch.base) == selected,
                onTap: () => onChanged(hexOf(swatch.base)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.swatch, required this.selected, required this.onTap});

  final YkCourseSwatch swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: swatch.nom,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: swatch.base,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? YkColors.textPrimary(context) : Colors.transparent,
              width: 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}
