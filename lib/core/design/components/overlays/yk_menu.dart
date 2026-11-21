import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

class YkMenuItem<T> {
  const YkMenuItem({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// Menu contextuel — CDC_DESIGN §5.3.7. Bâti sur `PopupMenuButton`
/// natif (gère déjà positionnement, fermeture au tap extérieur, clavier).
class YkMenu<T> extends StatelessWidget {
  const YkMenu({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.tooltip,
  });

  final List<YkMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      color: YkColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.md)),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 18, color: YkColors.textSecondary(context)),
                  SizedBox(width: YkSpacing.sm),
                ],
                Text(item.label, style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context))),
              ],
            ),
          ),
      ],
      child: child,
    );
  }
}
