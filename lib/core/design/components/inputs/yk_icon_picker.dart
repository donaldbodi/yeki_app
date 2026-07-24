import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Sélecteur d'icône — CDC_DESIGN §5.3.2 (même principe que
/// [YkColorPicker], mais le jeu d'icônes est fourni par l'appelant : pas
/// une règle métier figée comme les couleurs de cours).
class YkIconPicker extends StatelessWidget {
  const YkIconPicker({
    super.key,
    required this.icons,
    required this.selected,
    required this.onChanged,
    this.label,
  });

  final List<IconData> icons;
  final IconData? selected;
  final ValueChanged<IconData> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
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
            for (final icon in icons)
              _IconSwatch(icon: icon, selected: icon == selected, onTap: () => onChanged(icon)),
          ],
        ),
      ],
    );
  }
}

class _IconSwatch extends StatelessWidget {
  const _IconSwatch({required this.icon, required this.selected, required this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = YkColors.accent(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.15) : YkColors.surfaceVariant(context),
            shape: BoxShape.circle,
            border: Border.all(color: selected ? accent : Colors.transparent, width: 2),
          ),
          child: Icon(icon, color: selected ? accent : YkColors.textSecondary(context)),
        ),
      ),
    );
  }
}
