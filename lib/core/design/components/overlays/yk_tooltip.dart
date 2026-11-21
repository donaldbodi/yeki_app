import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Info-bulle — CDC_DESIGN §5.3.7. Fine surcouche de `Tooltip` natif
/// (déjà accessible/clavier), tokenisée.
class YkTooltip extends StatelessWidget {
  const YkTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: YkColors.textPrimary(context),
        borderRadius: BorderRadius.circular(YkRadius.xs),
      ),
      textStyle: YkTypography.caption(context).copyWith(color: YkColors.background(context)),
      child: child,
    );
  }
}
