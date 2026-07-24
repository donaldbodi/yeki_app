import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Forme de [YkProgress] — CDC_DESIGN §5.3.4.
enum YkProgressShape { linear, circular, xpRing }

/// Indicateur de progression — CDC_DESIGN §5.3.4 : linéaire, circulaire,
/// anneau d'XP. Déterminé (`value` non nul) ou indéterminé (`value`
/// nul) — n'existait nulle part sous forme d'anneau avant ce ticket
/// (seule une barre linéaire legacy existait).
class YkProgress extends StatelessWidget {
  const YkProgress({
    super.key,
    this.value,
    this.shape = YkProgressShape.linear,
    this.color,
    this.size = 48,
    this.strokeWidth = 6,
    this.centerLabel,
  });

  /// 0..1, ou `null` pour un indicateur indéterminé.
  final double? value;
  final YkProgressShape shape;
  final Color? color;
  final double size;
  final double strokeWidth;

  /// Affiché au centre — utile pour l'anneau d'XP (ex. « 320 XP »).
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? YkColors.accent(context);
    final bg = YkColors.border(context);

    switch (shape) {
      case YkProgressShape.linear:
        return ClipRRect(
          borderRadius: BorderRadius.circular(YkRadius.full),
          child: LinearProgressIndicator(
            value: value,
            color: fg,
            backgroundColor: bg,
            minHeight: strokeWidth,
          ),
        );
      case YkProgressShape.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value,
            color: fg,
            backgroundColor: bg,
            strokeWidth: strokeWidth,
          ),
        );
      case YkProgressShape.xpRing:
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  color: fg,
                  backgroundColor: bg,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                ),
              ),
              if (centerLabel != null)
                Text(
                  centerLabel!,
                  textAlign: TextAlign.center,
                  style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                ),
            ],
          ),
        );
    }
  }
}
