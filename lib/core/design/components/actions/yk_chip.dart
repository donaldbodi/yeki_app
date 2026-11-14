import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Variante de [YkChip] — CDC_DESIGN §5.3.1.
enum YkChipVariant { filter, input, assist, suggestion }

/// Puce — CDC_DESIGN §5.3.1. `accentColor` (ex. couleur de cours) est
/// reçu de l'appelant, jamais lu depuis `YkCourseColors.palette`
/// directement.
class YkChip extends StatelessWidget {
  const YkChip({
    super.key,
    required this.label,
    this.variant = YkChipVariant.assist,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
    this.onPressed,
    this.accentColor,
    this.avatar,
  });

  final String label;
  final YkChipVariant variant;

  /// Utilisé pour [YkChipVariant.filter].
  final bool selected;
  final ValueChanged<bool>? onSelected;

  /// Utilisé pour [YkChipVariant.input].
  final VoidCallback? onDeleted;

  /// Utilisé pour [YkChipVariant.assist]/[YkChipVariant.suggestion].
  final VoidCallback? onPressed;

  final Color? accentColor;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? YkColors.accent(context);
    final labelStyle = YkTypography.bodySm(context);

    switch (variant) {
      case YkChipVariant.filter:
        return FilterChip(
          label: Text(label, style: labelStyle),
          selected: selected,
          onSelected: onSelected,
          avatar: avatar,
          selectedColor: accent.withValues(alpha: 0.15),
          checkmarkColor: accent,
          side: BorderSide(color: selected ? accent : YkColors.border(context)),
          backgroundColor: YkColors.surfaceVariant(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.full)),
        );
      case YkChipVariant.input:
        return InputChip(
          label: Text(label, style: labelStyle),
          onDeleted: onDeleted,
          avatar: avatar,
          side: BorderSide(color: YkColors.border(context)),
          backgroundColor: YkColors.surfaceVariant(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.full)),
        );
      case YkChipVariant.assist:
        return ActionChip(
          label: Text(label, style: labelStyle.copyWith(color: accent)),
          onPressed: onPressed,
          avatar: avatar,
          side: BorderSide(color: accent.withValues(alpha: 0.4)),
          backgroundColor: accent.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.full)),
        );
      case YkChipVariant.suggestion:
        return ActionChip(
          label: Text(label, style: labelStyle),
          onPressed: onPressed,
          avatar: avatar,
          side: BorderSide(color: YkColors.border(context)),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.full)),
        );
    }
  }
}
