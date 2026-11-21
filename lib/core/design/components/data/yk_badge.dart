import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Variante de [YkBadge] — CDC_DESIGN §5.3.4.
enum YkBadgeVariant { numeric, dot, label }

/// Pastille — CDC_DESIGN §5.3.4 : numérique, point, ou étiquette.
class YkBadge extends StatelessWidget {
  const YkBadge({
    super.key,
    this.count,
    this.label,
    this.variant = YkBadgeVariant.numeric,
    this.color,
  }) : assert(
         variant != YkBadgeVariant.label || label != null,
         'YkBadge.label exige un libellé.',
       );

  final int? count;
  final String? label;
  final YkBadgeVariant variant;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? YkColors.error;

    switch (variant) {
      case YkBadgeVariant.numeric:
        if (count == null || count! <= 0) return const SizedBox.shrink();
        return Semantics(
          label: '$count',
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: YkSpacing.xs, vertical: 2),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(YkRadius.full)),
            child: Text(
              count! > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: YkTypography.caption(context).copyWith(color: YkColors.textOnPrimary),
            ),
          ),
        );
      case YkBadgeVariant.dot:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        );
      case YkBadgeVariant.label:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(YkRadius.full),
          ),
          child: Text(label!, style: YkTypography.caption(context).copyWith(color: bg)),
        );
    }
  }
}
